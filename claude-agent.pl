#!/usr/bin/perl
# claude-agent.pl — Self-contained Claude API agent for iBook G4
# (Mac OS X 10.4 Tiger, Perl 5.8.6). Has no external CPAN module dependencies.
#
# Prerequisite: /usr/local/claude-toolchain/bin/curl (with TLS 1.2/1.3 support),
#               built via ~/claude-build/build/remote-build-*.sh, must be available.
#
# Usage:
#   export ANTHROPIC_API_KEY=sk-ant-...
#   perl claude-agent.pl

use strict;
use warnings;
use utf8;  # Interpret UTF-8 literals in this file
use Encode qw(decode encode FB_DEFAULT);

# Explicitly handle screen output as UTF-8.
binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

# STDIN is deliberately kept as raw bytes (without :encoding layer).
# In Perl 5.8.6, PerlIO :encoding(UTF-8) during interactive keyboard reading
# where bytes arrive incrementally can split multibyte characters across read
# buffer boundaries, causing "utf8 does not map to Unicode" encoding errors
# (this does not happen with bulk input via pipes). Therefore, we read full lines
# as raw bytes first and decode them together at the end (in the while loop below).

# Adding :encoding disables STDOUT autoflush, which can delay prompt display
# until the API response arrives, so we explicitly flush each time.
$| = 1;

# ------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------
my $CURL      = $ENV{CLAUDE_CURL} || '/usr/local/claude-toolchain/bin/curl';
my $CACERT    = $ENV{CLAUDE_CACERT} || '/usr/local/claude-toolchain/cacert.pem';
my $MAX_TOKENS = 4096;
# Same path used by setup.sh. Used when saving keys entered via /claude or /gemini
# (fallback write target when not using setup.sh).
my $ENV_FILE_PATH = ($ENV{HOME} || '.') . '/.claude-agent-env';

# Theme-safe ANSI attributes (zero hardcoded colors; adapts to Terminal profile)
my $COLOR_RESET = "\x1b[0m";   # Default foreground and background
my $COLOR_USER  = "\x1b[2m";   # Dim/Faint (secondary text; degrades to default foreground on older terminals)
my $COLOR_MODEL = "\x1b[1m";   # Bold (high contrast using profile's configured Bold text color/weight)
if (!-t STDOUT || exists $ENV{NO_COLOR}) {
    $COLOR_RESET = '';
    $COLOR_USER  = '';
    $COLOR_MODEL = '';
}

# Provider switching. CLAUDE_PROVIDER=gemini uses the Gemini API free tier with no
# credit card required (default is Anthropic). Can also be switched during conversation
# via /claude or /gemini (see configure_provider below).
my ($PROVIDER, $API_KEY, $MODEL, $API_URL, $ANTHROPIC_VERSION);

# Autonomous tool execution mode. When enabled, tools that normally require
# confirmation (write_file, run_shell) execute immediately without prompting.
our $AUTO_MODE = $ENV{CLAUDE_AUTO_MODE} ? 1 : 0;

# (Re)configures $API_KEY, $MODEL, $API_URL, etc. according to $provider.
# Called at startup and by /claude and /gemini commands during conversation.
# If corresponding environment variables (ANTHROPIC_API_KEY / GEMINI_API_KEY)
# are missing, it dies — at startup this exits the program; during interactive
# switching, the caller catches with eval and stays on current provider.
sub configure_provider {
    my ($provider) = @_;
    if ($provider eq 'gemini') {
        $ENV{GEMINI_API_KEY} or die "GEMINI_API_KEY is not set.\n";
        $API_KEY = $ENV{GEMINI_API_KEY};
        $MODEL   = $ENV{CLAUDE_MODEL} || 'gemini-3.5-flash-lite';
        $API_URL = "https://generativelanguage.googleapis.com/v1beta/models/$MODEL:generateContent";
    }
    elsif ($provider eq 'anthropic') {
        $ENV{ANTHROPIC_API_KEY} or die "ANTHROPIC_API_KEY is not set.\n";
        $API_KEY = $ENV{ANTHROPIC_API_KEY};
        $MODEL   = $ENV{CLAUDE_MODEL} || 'claude-sonnet-4-5-20250929';
        $API_URL = 'https://api.anthropic.com/v1/messages';
        $ANTHROPIC_VERSION = '2023-06-01';
    }
    elsif ($provider eq 'openai') {
        # Any OpenAI-compatible chat/completions endpoint. Intended for local LLMs
        # running on a faster machine on the LAN (llama.cpp / Ollama / LM Studio, etc.).
        # $OPENAI_BASE_URL should be in the form "http://host:port/v1".
        my $base = $ENV{OPENAI_BASE_URL}
            or die "OPENAI_BASE_URL is not set (e.g. http://192.168.1.50:8080/v1).\n";
        $base =~ s{/+$}{};
        $API_KEY = $ENV{OPENAI_API_KEY} || 'not-needed';  # Many servers do not require an API key
        $MODEL   = $ENV{CLAUDE_MODEL} || 'local-model';
        $API_URL = "$base/chat/completions";
    }
    else {
        die "Unknown provider '$provider' (use anthropic / gemini / openai).\n";
    }
    $PROVIDER = $provider;
}

unless (caller) {
    # Determine provider: if not explicitly specified, use Anthropic if key exists,
    # otherwise Gemini (free tier; new users are guided here).
    my $_want_provider = $ENV{CLAUDE_PROVIDER};
    if (!defined $_want_provider || $_want_provider eq '') {
        $_want_provider = $ENV{ANTHROPIC_API_KEY} ? 'anthropic' : 'gemini';
    }
    unless (eval { configure_provider($_want_provider); 1 }) {
        my $err = $@ || "Configuration error\n";
        # Only when launched without a Gemini key, guide user through obtaining one with steps.
        # Otherwise (Anthropic key unset, unknown provider, etc.), die as usual.
        if ($_want_provider eq 'gemini' && !$ENV{GEMINI_API_KEY}) {
            my $key = gemini_key_setup();
            unless (defined $key && $key ne '') {
                print "\nNo API key was set, so exiting.\n";
                exit 1;
            }
            $ENV{GEMINI_API_KEY} = $key;
            configure_provider('gemini');
        }
        else {
            die $err;
        }
    }
}

my $SYSTEM_PROMPT = <<'EOS';
You are a lightweight coding assistant running in the terminal of a
PowerPC iBook G4 (Mac OS X 10.4 Tiger). You have four tools available:
read_file, write_file, list_dir, and run_shell. Use them to read/write
files and run commands in the user's working directory. Keep replies
concise, and always reply in the same language the user wrote in
(if they write in Japanese, reply in Japanese; if English, reply in
English; and so on for other languages).

Environment quirks to keep in mind for run_shell, so you get it right on
the first try instead of trial-and-error (each attempt needs the user's
explicit y/N confirmation, so retries are especially disruptive here):
- The system's stock `curl` is linked against an old OpenSSL and cannot
  make HTTPS requests (TLS handshake failure). A modern, TLS-capable curl
  is available via the `$CLAUDE_CURL` environment variable instead - for
  any HTTPS fetch, use `"$CLAUDE_CURL" --cacert "$CLAUDE_CACERT" ...`
  rather than plain `curl`.
- If Python is needed, assume it's an old Python 2.x (no `urllib.request`,
  no f-strings, no `except X as e:` - use `except Exception, e:` and the
  legacy `urllib`/`urllib2` modules instead).
EOS

# ------------------------------------------------------------------
# Minimal JSON encoder/decoder (zero dependencies, recursive descent parser
# covering what is needed for Claude API message structures)
# ------------------------------------------------------------------
package MiniJSON;

sub encode {
    my ($v) = @_;
    my $r = ref $v;
    if ($r eq 'HASH') {
        return '{' . join(',', map {
            encode_string($_) . ':' . encode($v->{$_})
        } sort keys %$v) . '}';
    } elsif ($r eq 'ARRAY') {
        return '[' . join(',', map { encode($_) } @$v) . ']';
    } elsif (!defined $v) {
        return 'null';
    } elsif ($r eq 'SCALAR') {
        return $$v ? 'true' : 'false';
    } elsif ($v =~ /^-?\d+(\.\d+)?([eE][+-]?\d+)?$/) {
        return $v;
    } else {
        return encode_string($v);
    }
}

sub encode_string {
    my ($s) = @_;
    $s =~ s/([\\"])/\\$1/g;
    $s =~ s/\n/\\n/g;
    $s =~ s/\r/\\r/g;
    $s =~ s/\t/\\t/g;
    $s =~ s/([\x00-\x1f])/sprintf('\\u%04x', ord($1))/ge;
    return '"' . $s . '"';
}

# decode: string -> Perl data structure. Parses while advancing pos.
sub decode {
    my ($text) = @_;
    my $pos = 0;
    my $val = _decode_value(\$text, \$pos);
    return $val;
}

sub _skip_ws {
    my ($t, $p) = @_;
    $$p++ while $$p < length($$t) && substr($$t, $$p, 1) =~ /[\s]/;
}

sub _decode_value {
    my ($t, $p) = @_;
    _skip_ws($t, $p);
    my $c = substr($$t, $$p, 1);
    if ($c eq '{') { return _decode_object($t, $p); }
    if ($c eq '[') { return _decode_array($t, $p); }
    if ($c eq '"') { return _decode_string($t, $p); }
    if (substr($$t, $$p, 4) eq 'true') { $$p += 4; return 1; }
    if (substr($$t, $$p, 5) eq 'false') { $$p += 5; return 0; }
    if (substr($$t, $$p, 4) eq 'null') { $$p += 4; return undef; }
    # number
    if (substr($$t, $$p) =~ /^(-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)/) {
        $$p += length($1);
        return $1 + 0;
    }
    die "JSON parse error at pos $$p: " . substr($$t, $$p, 30) . "\n";
}

sub _decode_object {
    my ($t, $p) = @_;
    my %h;
    $$p++; # {
    _skip_ws($t, $p);
    if (substr($$t, $$p, 1) eq '}') { $$p++; return \%h; }
    while (1) {
        _skip_ws($t, $p);
        my $key = _decode_string($t, $p);
        _skip_ws($t, $p);
        $$p++; # :
        my $val = _decode_value($t, $p);
        $h{$key} = $val;
        _skip_ws($t, $p);
        my $c = substr($$t, $$p, 1);
        if ($c eq ',') { $$p++; next; }
        if ($c eq '}') { $$p++; last; }
        die "JSON parse error in object at pos $$p\n";
    }
    return \%h;
}

sub _decode_array {
    my ($t, $p) = @_;
    my @a;
    $$p++; # [
    _skip_ws($t, $p);
    if (substr($$t, $$p, 1) eq ']') { $$p++; return \@a; }
    while (1) {
        my $val = _decode_value($t, $p);
        push @a, $val;
        _skip_ws($t, $p);
        my $c = substr($$t, $$p, 1);
        if ($c eq ',') { $$p++; next; }
        if ($c eq ']') { $$p++; last; }
        die "JSON parse error in array at pos $$p\n";
    }
    return \@a;
}

sub _decode_string {
    my ($t, $p) = @_;
    $$p++; # opening "
    my $out = '';
    while (1) {
        my $c = substr($$t, $$p, 1);
        die "unterminated string\n" if $c eq '';
        if ($c eq '"') { $$p++; last; }
        if ($c eq '\\') {
            $$p++;
            my $e = substr($$t, $$p, 1);
            if ($e eq 'n') { $out .= "\n"; }
            elsif ($e eq 't') { $out .= "\t"; }
            elsif ($e eq 'r') { $out .= "\r"; }
            elsif ($e eq 'b') { $out .= "\b"; }
            elsif ($e eq 'f') { $out .= "\f"; }
            elsif ($e eq 'u') {
                my $hex = substr($$t, $$p + 1, 4);
                $out .= chr(hex($hex));
                $$p += 4;
            } else { $out .= $e; }
            $$p++;
        } else {
            $out .= $c;
            $$p++;
        }
    }
    return $out;
}

package main;

# ------------------------------------------------------------------
# curl invocation (uses newly built TLS 1.2/1.3 capable curl)
# ------------------------------------------------------------------
sub call_api {
    # $headers is an arrayref of header strings (e.g. "x-api-key: ...").
    # Thin transport layer that takes URL/headers from outside per provider;
    # this sub itself has no knowledge of whether it's Anthropic or Gemini.
    my ($url, $headers, $body_json, $method) = @_;
    $method = defined $method ? uc($method) : 'POST';
    my $has_body = ($method ne 'GET' && defined $body_json) ? 1 : 0;

    my $tmp_req    = "/tmp/claude-agent-req-$$.json";
    my $tmp_resp   = "/tmp/claude-agent-resp-$$.json";
    my $tmp_config = "/tmp/claude-agent-curlcfg-$$.txt";

    if ($has_body) {
        open(my $fh, '>:encoding(UTF-8)', $tmp_req) or die "cannot write $tmp_req: $!\n";
        print $fh $body_json;
        close $fh;
    }

    # Pass headers via curl config file (-K) rather than command line args
    # to avoid exposing API keys in ps output
    open(my $cf, '>', $tmp_config) or die "cannot write $tmp_config: $!\n";
    chmod 0600, $tmp_config;
    print $cf qq(url = "$url"\n);
    print $cf qq(request = "$method"\n);
    # cacert is only needed for TLS. Local LLMs on LAN often use http://,
    # in which case it works fine without a cacert file, so do not pass it.
    print $cf qq(cacert = "$CACERT"\n) if $url =~ m{^https://}i;
    for my $h (@$headers) {
        print $cf qq(header = "$h"\n);
    }
    print $cf qq(data-binary = "\@$tmp_req"\n) if $has_body;
    print $cf qq(output = "$tmp_resp"\n);
    print $cf qq(write-out = "%{http_code}"\n);
    print $cf qq(silent\n);
    print $cf qq(show-error\n);
    close $cf;

    my $http_code = `@{[quote($CURL)]} -K @{[quote($tmp_config)]}`;
    unlink $tmp_req if $has_body;
    unlink $tmp_config;

    # For the same reason as STDIN (see comments at top), we do not use the
    # :encoding(UTF-8) layer here. In Perl 5.8.6, PerlIO :encoding(UTF-8) can split
    # multibyte characters across read buffer boundaries when reading responses
    # containing multibyte characters, causing "utf8 does not map to Unicode"
    # warnings and text corruption. Reading all raw bytes first and decoding them
    # together at the end avoids this issue.
    open(my $rf, '<', $tmp_resp) or die "cannot read response: $!\n";
    local $/;
    my $resp_body_bytes = <$rf>;
    close $rf;
    unlink $tmp_resp;
    my $resp_body = decode('UTF-8', $resp_body_bytes, FB_DEFAULT);

    if ($http_code !~ /^2/) {
        die "API error (HTTP $http_code): $resp_body\n";
    }

    return MiniJSON::decode($resp_body);
}

sub quote {
    my ($s) = @_;
    $s =~ s/'/'\\''/g;
    return "'$s'";
}

# ------------------------------------------------------------------
# Provider-specific request building and response parsing
#
# Conversation history (@messages) is always kept internally in Anthropic's
# content blocks format (role => user/assistant, content => string or
# [{type=>text/tool_use/tool_result, ...}, ...]). When using Gemini, this internal
# format is converted to Gemini's contents/parts format just before calling the API,
# and converted back to internal format as soon as the response arrives.
# This keeps the conversation loop and run_tool completely provider-agnostic.
# ------------------------------------------------------------------

sub build_headers {
    if ($PROVIDER eq 'gemini') {
        return [ "x-goog-api-key: $API_KEY", "content-type: application/json" ];
    }
    if ($PROVIDER eq 'openai') {
        return [ "authorization: Bearer $API_KEY", "content-type: application/json" ];
    }
    return [
        "x-api-key: $API_KEY",
        "anthropic-version: $ANTHROPIC_VERSION",
        "content-type: application/json",
    ];
}

sub build_request {
    my ($messages, $tools, $system) = @_;
    return build_request_gemini($messages, $tools, $system)   if $PROVIDER eq 'gemini';
    return build_request_openai($messages, $tools, $system)   if $PROVIDER eq 'openai';
    return build_request_anthropic($messages, $tools, $system);
}

sub build_request_anthropic {
    my ($messages, $tools, $system) = @_;
    return {
        model      => $MODEL,
        max_tokens => $MAX_TOKENS,
        system     => $system,
        messages   => $messages,
        tools      => $tools,
    };
}

sub build_request_gemini {
    my ($messages, $tools, $system) = @_;

    my @contents;
    for my $msg (@$messages) {
        my $role = $msg->{role} eq 'assistant' ? 'model' : 'user';
        my @parts;
        if (!ref $msg->{content}) {
            # Raw text entered directly by the user, not divided into blocks
            push @parts, { text => $msg->{content} };
        }
        else {
            for my $block (@{ $msg->{content} }) {
                if ($block->{type} eq 'text') {
                    my $part = { text => $block->{text} };
                    $part->{thoughtSignature} = $block->{thought_signature} if defined $block->{thought_signature};
                    push @parts, $part;
                }
                elsif ($block->{type} eq 'tool_use') {
                    my $part = { functionCall => { name => $block->{name}, args => $block->{input} } };
                    # Gemini 3.x returns a 400 error unless the same thoughtSignature
                    # received with functionCall is reattached when sending it back
                    # (it worked without it up to Gemini 2.5, but became mandatory in 3.x).
                    $part->{thoughtSignature} = $block->{thought_signature} if defined $block->{thought_signature};
                    push @parts, $part;
                }
                elsif ($block->{type} eq 'tool_result') {
                    # Gemini correlates tool results by name rather than tool_use_id
                    push @parts, {
                        functionResponse => {
                            name     => $block->{name},
                            response => { output => $block->{content} },
                        },
                    };
                }
            }
        }
        push @contents, { role => $role, parts => \@parts };
    }

    my @function_declarations = map {
        +{ name => $_->{name}, description => $_->{description}, parameters => $_->{input_schema} }
    } @$tools;

    return {
        contents          => \@contents,
        systemInstruction => { parts => [ { text => $system } ] },
        tools             => [ { functionDeclarations => \@function_declarations } ],
        generationConfig  => {
            maxOutputTokens => $MAX_TOKENS,
            thinkingConfig  => _gemini_thinking_config(),
        },
    };
}

# In Gemini 3.x, omitting thinkingLevel defaults to "HIGH" (think as deeply as possible),
# which can take dozens of seconds before the first character appears even for simple questions
# (verified on hardware). For interactive use on this low-powered iBook, we default to LOW
# for speed, and allow CLAUDE_GEMINI_THINKING=high to restore original behavior.
# Gemini 2.5 uses thinkingBudget (0..24576, -1 for dynamic) rather than thinkingLevel,
# so we branch on the model name.
sub _gemini_thinking_config {
    my $want_high = lc($ENV{CLAUDE_GEMINI_THINKING} || 'low') eq 'high';
    if ($MODEL =~ /^gemini-3/) {
        return { thinkingLevel => $want_high ? 'HIGH' : 'LOW' };
    }
    return { thinkingBudget => $want_high ? -1 : 0 };
}

# OpenAI compatible (chat/completions). Converts internal format (Anthropic content blocks)
# to OpenAI messages array. system is not a separate field but a leading role=system message.
# assistant tool_use becomes tool_calls[].function with arguments as a JSON string
# (OpenAI spec). tool_result becomes an independent role=tool message (linked by tool_call_id).
sub build_request_openai {
    my ($messages, $tools, $system) = @_;

    my @out = ({ role => 'system', content => $system });
    for my $msg (@$messages) {
        if (!ref $msg->{content}) {
            push @out, { role => $msg->{role}, content => $msg->{content} };
            next;
        }
        if ($msg->{role} eq 'assistant') {
            my $text = '';
            my @tool_calls;
            for my $block (@{ $msg->{content} }) {
                if ($block->{type} eq 'text') {
                    $text .= $block->{text};
                }
                elsif ($block->{type} eq 'tool_use') {
                    push @tool_calls, {
                        id       => $block->{id},
                        type     => 'function',
                        function => {
                            name      => $block->{name},
                            arguments => MiniJSON::encode($block->{input} || {}),
                        },
                    };
                }
            }
            my $m = { role => 'assistant', content => $text };
            $m->{tool_calls} = \@tool_calls if @tool_calls;
            push @out, $m;
        }
        else {
            # User-side blocks = run_tool results (tool_result).
            # In OpenAI, each becomes an independent role=tool message.
            for my $block (@{ $msg->{content} }) {
                if ($block->{type} eq 'tool_result') {
                    push @out, {
                        role         => 'tool',
                        tool_call_id => $block->{tool_use_id},
                        content      => $block->{content},
                    };
                }
                elsif ($block->{type} eq 'text') {
                    push @out, { role => 'user', content => $block->{text} };
                }
            }
        }
    }

    my @tool_defs = map {
        +{ type => 'function', function => {
            name        => $_->{name},
            description => $_->{description},
            parameters  => $_->{input_schema},
        } }
    } @$tools;

    my $req = {
        model      => $MODEL,
        messages   => \@out,
        max_tokens => $MAX_TOKENS,
    };
    $req->{tools} = \@tool_defs if @tool_defs;
    return $req;
}

sub parse_response {
    my ($resp) = @_;
    return parse_response_gemini($resp)   if $PROVIDER eq 'gemini';
    return parse_response_openai($resp)   if $PROVIDER eq 'openai';
    return parse_response_anthropic($resp);
}

sub parse_response_openai {
    my ($resp) = @_;
    if ($resp->{error}) {
        my $e = $resp->{error};
        die "API error: " . (ref $e ? MiniJSON::encode($e) : $e) . "\n";
    }
    my $msg = $resp->{choices} && $resp->{choices}[0] && $resp->{choices}[0]{message};
    die "API error: no choices in response: " . MiniJSON::encode($resp) . "\n" unless $msg;

    my @blocks;
    if (defined $msg->{content} && $msg->{content} ne '') {
        push @blocks, { type => 'text', text => $msg->{content} };
    }
    for my $tc (@{ $msg->{tool_calls} || [] }) {
        my $args = $tc->{function}{arguments};
        my $input = eval { MiniJSON::decode($args) } || {};
        push @blocks, {
            type  => 'tool_use',
            id    => $tc->{id} || ('call-' . scalar(@blocks)),
            name  => $tc->{function}{name},
            input => $input,
        };
    }
    return @blocks;
}

sub parse_response_anthropic {
    my ($resp) = @_;
    if ($resp->{type} && $resp->{type} eq 'error') {
        die "API error: " . MiniJSON::encode($resp) . "\n";
    }
    return @{ $resp->{content} || [] };
}

my $gemini_call_seq = 0;

sub parse_response_gemini {
    my ($resp) = @_;
    if ($resp->{error}) {
        die "API error: " . MiniJSON::encode($resp->{error}) . "\n";
    }
    my $candidate = $resp->{candidates} && $resp->{candidates}[0];
    my @blocks;
    for my $part (@{ ($candidate && $candidate->{content}{parts}) || [] }) {
        # When Gemini uses thinking, parts representing intermediate thought processes
        # may be returned in the response (flagged with thought: true).
        # These are internal drafts rather than final responses for the user;
        # passing them through causes draft revisions to appear directly on screen
        # as thoughts evolve (reported on physical PowerBook G4).
        # This is separate from thoughtSignature (signature for continuation),
        # so we simply skip these parts and take only final response parts.
        next if $part->{thought};
        if (defined $part->{text}) {
            my $block = { type => 'text', text => $part->{text} };
            $block->{thought_signature} = $part->{thoughtSignature} if defined $part->{thoughtSignature};
            push @blocks, $block;
        }
        elsif ($part->{functionCall}) {
            $gemini_call_seq++;
            my $block = {
                type  => 'tool_use',
                # Gemini functionCall has no native id, so generate a substitute ID
                # to align with Anthropic format internal representation when sending tool_result
                id    => "gemini-call-$gemini_call_seq",
                name  => $part->{functionCall}{name},
                input => $part->{functionCall}{args} || {},
            };
            # Reattached as-is when returning functionCall in the next turn
            # (see corresponding elsif in build_request_gemini)
            $block->{thought_signature} = $part->{thoughtSignature} if defined $part->{thoughtSignature};
            push @blocks, $block;
        }
    }
    return @blocks;
}

# ------------------------------------------------------------------
# Provider model discovery & schema adapters
# ------------------------------------------------------------------
sub fetch_models {
    my ($provider) = @_;
    $provider = (defined $provider && $provider ne '') ? $provider : $PROVIDER;
    if (!defined $provider || $provider eq '') {
        return wantarray ? (undef, "No provider configured") : undef;
    }

    my ($models, $err);
    eval {
        if ($provider eq 'anthropic') {
            $models = _fetch_models_anthropic();
        }
        elsif ($provider eq 'gemini') {
            $models = _fetch_models_gemini();
        }
        elsif ($provider eq 'openai') {
            $models = _fetch_models_openai();
        }
        else {
            die "Unknown provider '$provider'\n";
        }
    };
    if ($@) {
        $err = $@;
        $err =~ s/ at \S+ line \d+.*//s;
        $err =~ s/^\s+|\s+$//g;
        return wantarray ? (undef, $err) : undef;
    }

    return wantarray ? ($models, undef) : $models;
}

sub _fetch_models_anthropic {
    my $key = ($PROVIDER && $PROVIDER eq 'anthropic' && defined $API_KEY && $API_KEY ne '')
        ? $API_KEY
        : $ENV{ANTHROPIC_API_KEY};
    die "ANTHROPIC_API_KEY is not set.\n" unless defined $key && $key ne '';

    my $url = 'https://api.anthropic.com/v1/models?limit=100';
    my $ver = (defined $ANTHROPIC_VERSION && $ANTHROPIC_VERSION ne '')
        ? $ANTHROPIC_VERSION
        : '2023-06-01';
    my $headers = [ "x-api-key: $key", "anthropic-version: $ver" ];

    my $resp = call_api($url, $headers, undef, 'GET');
    die "Invalid response: expected JSON object\n" unless ref $resp eq 'HASH';
    if ($resp->{error}) {
        my $e = $resp->{error};
        die "API error: " . (ref $e ? MiniJSON::encode($e) : $e) . "\n";
    }
    my $data = $resp->{data};
    die "Invalid response from Anthropic: missing data array\n" unless ref $data eq 'ARRAY';

    my @models;
    for my $item (@$data) {
        next unless ref $item eq 'HASH' && defined $item->{id};
        my $display = (defined $item->{display_name} && $item->{display_name} ne '')
            ? $item->{display_name}
            : $item->{id};
        push @models, { id => $item->{id}, display => $display };
    }
    return \@models;
}

sub _fetch_models_gemini {
    my $key = ($PROVIDER && $PROVIDER eq 'gemini' && defined $API_KEY && $API_KEY ne '')
        ? $API_KEY
        : $ENV{GEMINI_API_KEY};
    die "GEMINI_API_KEY is not set.\n" unless defined $key && $key ne '';

    my $url = 'https://generativelanguage.googleapis.com/v1beta/models?pageSize=100';
    my $headers = [ "x-goog-api-key: $key" ];

    my $resp = call_api($url, $headers, undef, 'GET');
    die "Invalid response: expected JSON object\n" unless ref $resp eq 'HASH';
    if ($resp->{error}) {
        my $e = $resp->{error};
        die "API error: " . (ref $e ? MiniJSON::encode($e) : $e) . "\n";
    }
    my $list = $resp->{models};
    die "Invalid response from Gemini: missing models array\n" unless ref $list eq 'ARRAY';

    my @models;
    for my $item (@$list) {
        next unless ref $item eq 'HASH' && defined $item->{name};
        my $methods = $item->{supportedGenerationMethods};
        my $can_generate = 0;
        if (ref $methods eq 'ARRAY') {
            for my $m (@$methods) {
                if (defined $m && $m eq 'generateContent') {
                    $can_generate = 1;
                    last;
                }
            }
        }
        next unless $can_generate;

        my $id = $item->{name};
        $id =~ s{^models/}{};
        my $display = (defined $item->{displayName} && $item->{displayName} ne '')
            ? $item->{displayName}
            : $id;
        push @models, { id => $id, display => $display };
    }
    return \@models;
}

sub _fetch_models_openai {
    my $base;
    if (defined $API_URL && $API_URL =~ m{^(.*)/chat/completions$}) {
        $base = $1;
    }
    if (!defined $base || $base eq '') {
        $base = $ENV{OPENAI_BASE_URL};
    }
    die "OPENAI_BASE_URL is not set.\n" unless defined $base && $base ne '';
    $base =~ s{/+$}{};

    my $key = ($PROVIDER && $PROVIDER eq 'openai' && defined $API_KEY && $API_KEY ne '')
        ? $API_KEY
        : (defined $ENV{OPENAI_API_KEY} ? $ENV{OPENAI_API_KEY} : 'not-needed');

    my $url = "$base/models";
    my $headers = [];
    if (defined $key && $key ne '' && $key ne 'not-needed') {
        push @$headers, "authorization: Bearer $key";
    }

    my $resp = call_api($url, $headers, undef, 'GET');
    die "Invalid response: expected JSON object\n" unless ref $resp eq 'HASH';
    if ($resp->{error}) {
        my $e = $resp->{error};
        die "API error: " . (ref $e ? MiniJSON::encode($e) : $e) . "\n";
    }
    my $data = $resp->{data};
    die "Invalid response from OpenAI: missing data array\n" unless ref $data eq 'ARRAY';

    my @models;
    for my $item (@$data) {
        next unless ref $item eq 'HASH' && defined $item->{id};
        my $display = (defined $item->{display_name} && $item->{display_name} ne '')
            ? $item->{display_name}
            : (defined $item->{name} && $item->{name} ne '')
                ? $item->{name}
                : $item->{id};
        push @models, { id => $item->{id}, display => $display };
    }
    return \@models;
}

# ------------------------------------------------------------------
# Interactive model selection UI
# ------------------------------------------------------------------
our $FORCE_RAW = 0;

sub _normalize_models {
    my ($models_ref) = @_;
    return () unless defined $models_ref && ref($models_ref) eq 'ARRAY';
    my @normalized;
    for my $m (@$models_ref) {
        if (ref($m) eq 'HASH') {
            next unless defined $m->{id} && $m->{id} ne '';
            my $disp = (defined $m->{display} && $m->{display} ne '') ? $m->{display} : $m->{id};
            push @normalized, { id => $m->{id}, display => $disp };
        }
        elsif (defined $m && !ref($m) && $m ne '') {
            push @normalized, { id => $m, display => $m };
        }
    }
    return @normalized;
}

sub _select_model_nontty {
    my ($models_ref, $current_model, $in_fh, $out_fh) = @_;
    print $out_fh "Available models:\n";
    for (my $i = 0; $i < @$models_ref; $i++) {
        my $m = $models_ref->[$i];
        my $cur = (defined $current_model && $m->{id} eq $current_model) ? " (current)" : "";
        my $label = ($m->{display} ne $m->{id}) ? "$m->{display} ($m->{id})" : $m->{id};
        print $out_fh sprintf("  %2d) %s%s\n", $i + 1, $label, $cur);
    }
    print $out_fh "Select model [1-" . scalar(@$models_ref) . ", or Enter to cancel]: ";
    my $line = <$in_fh>;
    return undef unless defined $line;
    $line =~ s/^\s+|\s+$//g;
    return undef if $line eq '' || $line =~ /^(?:q|quit|exit|cancel)$/i;

    if ($line =~ /^\d+$/ && $line >= 1 && $line <= @$models_ref) {
        return $models_ref->[$line - 1]->{id};
    }
    for my $m (@$models_ref) {
        return $m->{id} if $m->{id} eq $line;
    }
    return undef;
}

sub _read_menu_key {
    my ($in_fh) = @_;
    my $ch;
    my $n = sysread($in_fh, $ch, 1);
    return ('eof', undef) unless defined $n && $n > 0;

    my $b = ord($ch);
    if ($b == 0x03) {
        return ('cancel', 'ctrl_c');
    }
    if ($b == 0x0d || $b == 0x0a) {
        return ('enter', undef);
    }
    if ($b == 0x7f || $b == 0x08) {
        return ('backspace', undef);
    }
    if ($b >= ord('0') && $b <= ord('9')) {
        return ('digit', $ch);
    }
    if ($b == 0x1b) {
        my $fn = fileno($in_fh);
        return ('cancel', 'esc') unless defined $fn;
        my $rin = '';
        vec($rin, $fn, 1) = 1;
        my $nfound = select(my $rout = $rin, undef, undef, 0.05);
        if (!defined $nfound || $nfound <= 0) {
            return ('cancel', 'esc');
        }
        my $c2;
        my $n2 = sysread($in_fh, $c2, 1);
        return ('cancel', 'esc') unless defined $n2 && $n2 > 0;

        if ($c2 eq '[' || $c2 eq 'O') {
            my $c3;
            my $n3 = sysread($in_fh, $c3, 1);
            return ('ignore', undef) unless defined $n3 && $n3 > 0;

            if ($c3 eq 'A') { return ('up', undef); }
            if ($c3 eq 'B') { return ('down', undef); }
            if ($c3 eq 'C') { return ('down', undef); }
            if ($c3 eq 'D') { return ('up', undef); }

            if ($c3 =~ /[0-9]/) {
                while (1) {
                    my $cx;
                    my $nx = sysread($in_fh, $cx, 1);
                    last unless defined $nx && $nx > 0;
                    last if $cx eq '~' || $cx =~ /[a-zA-Z]/;
                }
                return ('ignore', undef);
            }
        }
        return ('ignore', undef);
    }

    return ('other', $ch);
}

sub _render_menu_lines {
    my ($models, $cursor, $window_start, $page_size, $current_model, $num_buf) = @_;
    my $total = scalar(@$models);
    my $window_end = $window_start + $page_size - 1;
    $window_end = $total - 1 if $window_end >= $total;

    my @lines;
    my $header;
    if ($total > $page_size) {
        $header = sprintf("Select Model [showing %d-%d of %d] (Up/Down, Enter: select, Esc: cancel):",
            $window_start + 1, $window_end + 1, $total);
    }
    else {
        $header = sprintf("Select Model [1-%d] (Up/Down or 1-%d, Enter: select, Esc: cancel):", $total, $total);
    }
    push @lines, $header;

    for (my $i = $window_start; $i <= $window_end; $i++) {
        my $m = $models->[$i];
        my $prefix = ($i == $cursor) ? "> " : "  ";
        my $cur = (defined $current_model && $m->{id} eq $current_model) ? " (current)" : "";
        my $label = ($m->{display} ne $m->{id}) ? "$m->{display} ($m->{id})" : $m->{id};
        my $overhead = 6 + length($cur); # 2 prefix + 4 index ("%2d) ") + current indicator
        my $max_label_len = 78 - $overhead;
        if (length($label) > $max_label_len) {
            $label = substr($label, 0, $max_label_len - 3) . "...";
        }
        my $row = sprintf("%s%2d) %s%s", $prefix, $i + 1, $label, $cur);
        if ($i == $cursor && $COLOR_RESET ne '') {
            $row = "\x1b[1;7m" . $row . $COLOR_RESET;
        }
        push @lines, $row;
    }

    if (defined $num_buf && $num_buf ne '') {
        push @lines, "Jump to: $num_buf" . "_";
    }

    return @lines;
}

sub select_model_interactive {
    my ($models_ref, $current_model, $in_fh, $out_fh) = @_;
    $in_fh  = \*STDIN  unless defined $in_fh;
    $out_fh = \*STDOUT unless defined $out_fh;

    my @models = _normalize_models($models_ref);
    return undef unless @models;

    my $is_tty = -t $in_fh;
    if (!$is_tty && !$FORCE_RAW && !$ENV{CLAUDE_TEST_RAW}) {
        return _select_model_nontty(\@models, $current_model, $in_fh, $out_fh);
    }

    my $orig_stty;
    if ($is_tty) {
        $orig_stty = `stty -g 2>/dev/null`;
        chomp $orig_stty if defined $orig_stty;
        system('stty', 'raw', '-echo', '-opost');
    }

    my $PAGE_SIZE = 12;
    my $cursor = 0;
    if (defined $current_model) {
        for (my $i = 0; $i < @models; $i++) {
            if ($models[$i]{id} eq $current_model) {
                $cursor = $i;
                last;
            }
        }
    }

    my $window_start = 0;
    if ($cursor >= $PAGE_SIZE) {
        $window_start = $cursor - $PAGE_SIZE + 1;
    }

    my $num_buf = '';
    my $lines_drawn = 0;
    my $selected_id;

    eval {
        while (1) {
            if ($cursor < $window_start) {
                $window_start = $cursor;
            }
            elsif ($cursor >= $window_start + $PAGE_SIZE) {
                $window_start = $cursor - $PAGE_SIZE + 1;
            }

            my @menu_lines = _render_menu_lines(\@models, $cursor, $window_start, $PAGE_SIZE, $current_model, $num_buf);

            if ($lines_drawn > 0) {
                print $out_fh "\x1b[${lines_drawn}A\r";
            }
            for my $line (@menu_lines) {
                print $out_fh "\x1b[2K" . $line . "\r\n";
            }
            if ($lines_drawn > @menu_lines) {
                my $diff = $lines_drawn - @menu_lines;
                for (1 .. $diff) {
                    print $out_fh "\x1b[2K\r\n";
                }
                print $out_fh "\x1b[${diff}A\r";
            }
            $lines_drawn = scalar(@menu_lines);

            my ($action, $val) = _read_menu_key($in_fh);

            if ($action eq 'enter') {
                $selected_id = $models[$cursor]{id};
                last;
            }
            elsif ($action eq 'cancel' || $action eq 'eof') {
                $selected_id = undef;
                last;
            }
            elsif ($action eq 'up') {
                $num_buf = '';
                $cursor-- if $cursor > 0;
            }
            elsif ($action eq 'down') {
                $num_buf = '';
                $cursor++ if $cursor < @models - 1;
            }
            elsif ($action eq 'digit') {
                $num_buf .= $val;
                my $target = int($num_buf) - 1;
                if ($target >= 0 && $target < @models) {
                    $cursor = $target;
                }
                elsif ($target >= @models) {
                    $num_buf = $val;
                    my $t2 = int($num_buf) - 1;
                    $cursor = $t2 if ($t2 >= 0 && $t2 < @models);
                }
            }
            elsif ($action eq 'backspace') {
                if (length($num_buf) > 0) {
                    chop $num_buf;
                    if (length($num_buf) > 0) {
                        my $target = int($num_buf) - 1;
                        $cursor = $target if ($target >= 0 && $target < @models);
                    }
                }
            }
        }
    };
    my $eval_err = $@;

    if ($is_tty && defined $orig_stty && $orig_stty ne '') {
        system('stty', $orig_stty);
    }

    print $out_fh "\r\n";

    die $eval_err if $eval_err;
    return $selected_id;
}

sub get_current_model {
    return $MODEL;
}

sub get_current_provider {
    return $PROVIDER;
}

sub get_current_api_url {
    return $API_URL;
}

sub get_auto_mode {
    return $AUTO_MODE;
}

sub set_auto_mode {
    my ($val) = @_;
    $AUTO_MODE = $val ? 1 : 0;
    return $AUTO_MODE;
}

sub show_help {
    my ($out_fh) = @_;
    $out_fh ||= \*STDOUT;
    print $out_fh "\nAvailable commands:\n";
    print $out_fh "  /models  - View and switch available AI models\n";
    print $out_fh "  /claude  - Switch to Anthropic Claude\n";
    print $out_fh "  /gemini  - Switch to Google Gemini\n";
    print $out_fh "  /openai  - Switch to OpenAI-compatible endpoint\n";
    print $out_fh "  /auto    - Enable auto mode (run tools without confirmation)\n";
    print $out_fh "  /manual  - Enable manual mode (require tool confirmation)\n";
    print $out_fh "  /help    - Show available commands\n";
    print $out_fh "  exit     - Exit the agent (or Ctrl-D)\n";
}

sub handle_auto_command {
    my ($out_fh) = @_;
    $out_fh ||= \*STDOUT;
    set_auto_mode(1);
    print $out_fh "Auto mode enabled. Tools will execute without user confirmation.\n";
    return 1;
}

sub handle_manual_command {
    my ($out_fh) = @_;
    $out_fh ||= \*STDOUT;
    set_auto_mode(0);
    print $out_fh "Manual mode enabled. Tools will require user confirmation.\n";
    return 0;
}

sub handle_models_command {
    my ($in_fh, $out_fh) = @_;
    $out_fh ||= \*STDOUT;

    my ($models, $err) = fetch_models();
    if ($err || !defined $models || !@$models) {
        my $msg = defined $err ? $err : "No models found.";
        print $out_fh "Error fetching models: $msg\n";
        return undef;
    }

    my $selected = select_model_interactive($models, $MODEL, $in_fh, $out_fh);
    if (defined $selected && $selected ne '') {
        $MODEL = $selected;
        $ENV{CLAUDE_MODEL} = $selected;
        if (defined $PROVIDER && $PROVIDER eq 'gemini') {
            $API_URL = "https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent";
        }
        print $out_fh "Switched model to: $MODEL\n";
    }
    else {
        print $out_fh "Cancelled. Staying on $MODEL\n";
    }
    return $MODEL;
}

# ------------------------------------------------------------------
# Tool definitions and tool execution
# ------------------------------------------------------------------
my @TOOLS = (
    {
        name => 'read_file',
        description => 'Read file contents',
        input_schema => {
            type => 'object',
            properties => { path => { type => 'string', description => 'Path to the file to read' } },
            required => ['path'],
        },
    },
    {
        name => 'write_file',
        description => 'Write content to a file (overwrite)',
        input_schema => {
            type => 'object',
            properties => {
                path    => { type => 'string', description => 'Target file path' },
                content => { type => 'string', description => 'Content to write' },
            },
            required => ['path', 'content'],
        },
    },
    {
        name => 'list_dir',
        description => 'List contents of a directory',
        input_schema => {
            type => 'object',
            properties => { path => { type => 'string', description => 'Directory to list (defaults to current directory if omitted)' } },
            required => [],
        },
    },
    {
        name => 'run_shell',
        description => 'Execute a shell command and return stdout/stderr',
        input_schema => {
            type => 'object',
            properties => { command => { type => 'string', description => 'Shell command to execute' } },
            required => ['command'],
        },
    },
);

sub confirm {
    my ($msg) = @_;
    print "\n[Confirm] $msg\nProceed? [y/N] ";
    my $ans = read_line_interactive('', 0);
    return defined($ans) && $ans =~ /^y/i;
}

sub confirm_tool {
    my ($prompt) = @_;
    return 1 if $AUTO_MODE;
    return confirm($prompt);
}

# Display responses incrementally like a typewriter. Added based on feedback
# from physical PowerBook G4 where fast output scrolls too quickly to read.
# CLAUDE_TYPE_DELAY (seconds per char) adjusts speed; setting to 0 restores
# immediate display (original behavior). Pauses slightly longer on newlines.
# select(undef,undef,undef,$t) is a fractional second sleep without Time::HiRes.
sub slow_print {
    my ($text) = @_;
    my $delay = $ENV{CLAUDE_TYPE_DELAY};
    $delay = 0.006 unless defined $delay && $delay ne '';
    $delay = 0 + $delay;
    if ($delay <= 0) {
        print $text;
        return;
    }
    for my $ch (split //, $text) {
        print $ch;
        select(undef, undef, undef, $ch eq "\n" ? $delay * 12 : $delay);
    }
}

# ------------------------------------------------------------------
# Gemini API key setup helper (when started without a key)
# ------------------------------------------------------------------
# Displays numbered steps, optionally opens the page in a browser, and validates
# the pasted key by calling the API live. Returns the key string on success
# (caller sets $ENV{GEMINI_API_KEY} and calls configure_provider).
# Returns undef on cancel/failure.
sub gemini_key_setup {
    my $url = 'https://ai.google.dev/gemini-api/docs/api-key';
    print <<"GUIDE";

──────────────────────────────────────────────
 Get a Gemini API key
   (free tier, no credit card)
──────────────────────────────────────────────
 GEMINI_API_KEY is not set yet. Here is how to get a free key:

  1. Open this page in a browser:
       $url
  2. Sign in with a Google account (top right)
  3. Click the blue "Get a Gemini API key" button
     -> it takes you to Google AI Studio, "API keys"
  4. Click "Create API key" (top right)
  5. In the "Create API key" dialog, leave the defaults
     (key name as-is, project "Default Gemini Project")
     and click "Create API key" / "Create key"
  6. Copy the string it shows (starts with AIza...)



GUIDE

    if (-x '/usr/bin/open') {
        print "  Open this page in your browser now? [Y/n] ";
        my $a = read_line_interactive('', 0);
        return undef unless defined $a;
        if ($a !~ /^\s*n/i) {
            my $rc = system('open', $url);
            print $rc == 0
                ? "  -> opened.\n"
                : "  -> could not open it automatically; open the URL above by hand.\n";
        }
    }

    for my $attempt (1 .. 3) {
        my $key = read_secret_or_cancel(
            "\n  Paste the key and press Enter (Esc or Ctrl+C to cancel)\n"
          . "  key> ");
        return undef unless defined $key;
        $key =~ s/\A[\s"']+//;
        $key =~ s/[\s"']+\z//;
        if ($key eq '') {
            print "  Nothing entered.\n";
            next;
        }
        if ($key !~ /\AAIza[0-9A-Za-z_\-]{20,}\z/) {
            print "  * That does not look like a Gemini key (starts with AIza, ~39 chars).\n";
            print "    Try it anyway? [y/N] ";
            my $a = read_line_interactive('', 0);
            next unless defined $a && $a =~ /^\s*y/i;
        }

        print "  Checking the key...\n";
        my ($status, $detail) = _validate_gemini_key($key);
        if ($status eq 'ok') {
            print "  OK - the key works.\n";
            _maybe_save_gemini_key($key);
            return $key;
        }
        elsif ($status eq 'skip') {
            print "  (verification skipped: $detail)\n";
            _maybe_save_gemini_key($key);
            return $key;
        }
        elsif ($status eq 'bad_key') {
            print "  X - the key was rejected ($detail).\n";
            print "      Check for a copy/paste slip and that the whole key is there.\n";
        }
        elsif ($status eq 'api_disabled') {
            print "  X - the key is valid but the Generative Language API is not enabled ($detail).\n";
            print "      Recreate the key in AI Studio, or wait a bit and retry.\n";
        }
        else {
            print "  X - could not reach the API ($detail).\n";
            print "      Check that you are online.\n";
        }
        print "  (" . (3 - $attempt) . " left)\n" if $attempt < 3;
    }
    print "\n  Could not set up a key.\n";
    return undef;
}

# Send pasted key to Generative Language API models list endpoint to verify validity.
# Return value: ('ok'|'bad_key'|'api_disabled'|'network'|'skip', detail)
sub _validate_gemini_key {
    my ($key) = @_;
    return ('skip', 'curl not found')   unless -x $CURL;
    return ('skip', 'cacert not found') unless -f $CACERT;

    my $tmp_resp   = "/tmp/claude-agent-keychk-resp-$$.json";
    my $tmp_config = "/tmp/claude-agent-keychk-cfg-$$.txt";
    open(my $cf, '>', $tmp_config) or return ('network', "cannot create temp file: $!");
    chmod 0600, $tmp_config;
    print $cf qq(url = "https://generativelanguage.googleapis.com/v1beta/models"\n);
    print $cf qq(header = "x-goog-api-key: $key"\n);
    print $cf qq(cacert = "$CACERT"\n);
    print $cf qq(output = "$tmp_resp"\n);
    print $cf qq(write-out = "%{http_code}"\n);
    print $cf qq(max-time = "20"\n);
    print $cf qq(silent\n);
    print $cf qq(show-error\n);
    close $cf;

    my $http = `@{[quote($CURL)]} -K @{[quote($tmp_config)]} 2>/dev/null`;
    unlink $tmp_config;
    my $body = '';
    if (open(my $rf, '<', $tmp_resp)) { local $/; $body = <$rf>; close $rf; }
    unlink $tmp_resp;
    $body = '' unless defined $body;
    $http = '' unless defined $http;

    return ('ok', "HTTP $http")            if $http =~ /^2\d\d$/;
    return ('network', 'no response from curl') if $http eq '' || $http eq '000';
    return ('bad_key', "HTTP $http")       if $body =~ /API_KEY_INVALID/ || $http eq '400';
    return ('api_disabled', "HTTP $http")  if $body =~ /SERVICE_DISABLED|PERMISSION_DENIED|has not been used|is disabled/;
    return ('bad_key', "HTTP $http");
}

# Prompt whether to save key to ~/.claude-agent-env; if confirmed,
# strip existing GEMINI_API_KEY line and append new one.
sub _maybe_save_gemini_key {
    my ($key) = @_;
    print "\n  Save this key to $ENV_FILE_PATH so future runs pick it up automatically? [Y/n] ";
    my $a = read_line_interactive('', 0);
    return unless defined $a;
    return if $a =~ /^\s*n/i;

    my @keep;
    if (open(my $rf, '<', $ENV_FILE_PATH)) {
        while (my $l = <$rf>) {
            next if $l =~ /^\s*export\s+GEMINI_API_KEY=/;
            push @keep, $l;
        }
        close $rf;
    }
    push @keep, "export GEMINI_API_KEY=$key\n";
    if (open(my $wf, '>', $ENV_FILE_PATH)) {
        print $wf @keep;
        close $wf;
        chmod 0600, $ENV_FILE_PATH;
        print "  -> saved. It will be loaded automatically from now on.\n";
    }
    else {
        print "  -> could not save (cannot write $ENV_FILE_PATH).\n";
        print "     Please add the following line manually:\n";
        print "       export GEMINI_API_KEY=$key\n";
    }
}

# Read a single line secret (such as an API key) without echoing to screen.
# Unlike read_line_interactive, arrow keys are not supported (only key pasting
# is expected); instead, either Esc or Ctrl+C immediately returns undef to cancel
# (Esc is standard for canceling uncommitted input, Ctrl+C is standard for interrupting
# in terminal). Treating standalone ESC as cancel without waiting for following bytes
# is a simplification valid here because escape sequences like arrow keys do not need
# to be parsed. In stty raw mode, ISIG is disabled, so Ctrl+C (0x03) arrives as a raw byte.
# Return value: input string (raw bytes, without newline). undef on cancel.
sub read_secret_or_cancel {
    my ($prompt) = @_;
    print $prompt;

    my $orig_stty = `stty -g`;
    chomp $orig_stty;
    system('stty', 'raw', '-echo', '-opost');

    my $buf = '';
    my $cancelled = 0;
    while (1) {
        my $ch;
        my $n = sysread(STDIN, $ch, 1);
        last unless defined $n && $n > 0;
        my $b = ord($ch);
        if ($b == 0x1b || $b == 0x03) {  # Esc or Ctrl+C -> cancel
            $cancelled = 1;
            last;
        }
        elsif ($b == 0x0d || $b == 0x0a) {  # Enter
            last;
        }
        elsif ($b == 0x7f || $b == 0x08) {  # Backspace/Delete
            substr($buf, -1, 1, '') if length($buf) > 0;
        }
        elsif ($b >= 0x20) {
            $buf .= $ch;
        }
        # Ignore other control bytes
    }

    system('stty', $orig_stty) if defined $orig_stty && $orig_stty ne '';
    print "\n";
    return $cancelled ? undef : $buf;
}

# ------------------------------------------------------------------
# Line editing (simple readline with arrow key support)
#
# Standard <STDIN> has no cursor movement support, so pressing arrow keys
# causes raw escape sequences (ESC [ C, etc.) sent by the terminal to appear
# on screen. To prevent this, we set the terminal to raw mode via stty and
# implement simple line editing (left/right navigation, Backspace, up/down history)
# manually, reading byte by byte without external CPAN dependencies (Term::ReadLine, etc.).
# ------------------------------------------------------------------
{
    my @HISTORY;

    # For debugging: setting $ENV{CLAUDE_DEBUG_INPUT} to a file path logs raw bytes
    # received by read_line_interactive line by line. Temporary mechanism to inspect
    # what arrives during IME input on physical hardware.
    my $_dbg_last_t;
    sub _debug_log {
        return unless $ENV{CLAUDE_DEBUG_INPUT};
        open(my $fh, '>>', $ENV{CLAUDE_DEBUG_INPUT}) or return;
        # Prefix each line with seconds elapsed since previous log. Helps isolate whether
        # Enter is sent immediately upon IME confirmation or after a delay (different input path).
        # Time::HiRes is in Perl 5.8 core, so no extra dependency.
        my $dt = '';
        if (eval { require Time::HiRes; 1 }) {
            my $now = Time::HiRes::time();
            $dt = defined $_dbg_last_t ? sprintf('+%.3f ', $now - $_dbg_last_t) : '+0.000 ';
            $_dbg_last_t = $now;
        }
        # Elements of @_ are aliases to caller arguments, and string literals may be passed
        # directly. Modifying them in-place with s/// causes "Modification of a read-only value attempted"
        # (which previously caused a crash at startup). Always copy to a new variable before modifying.
        my $msg = join('', @_);
        $msg =~ s/^/$dt/mg if $dt ne '';
        print $fh $msg;
        close $fh;
    }

    # Return byte length of a UTF-8 character from its leading byte
    sub _utf8_char_len {
        my ($byte) = @_;
        my $b = ord($byte);
        return 1 if $b < 0x80;
        return 2 if ($b & 0xE0) == 0xC0;
        return 3 if ($b & 0xF0) == 0xE0;
        return 4 if ($b & 0xF8) == 0xF0;
        return 1;  # Advance 1 byte for invalid byte sequences
    }

    # Given a decoded character, return its display width on the terminal (halfwidth=1, fullwidth=2)
    sub _char_width {
        my ($ch) = @_;
        my $cp = ord($ch);
        return (
            ($cp >= 0x1100 && $cp <= 0x115F) ||
            ($cp >= 0x2E80 && $cp <= 0xA4CF) ||
            ($cp >= 0xAC00 && $cp <= 0xD7A3) ||
            ($cp >= 0xF900 && $cp <= 0xFAFF) ||
            ($cp >= 0xFF00 && $cp <= 0xFF60) ||
            ($cp >= 0xFFE0 && $cp <= 0xFFE6)
        ) ? 2 : 1;
    }

    # Given a decoded Perl string, return the sum of display widths
    # (halfwidth=1, fullwidth=2)
    sub _display_width_chars {
        my ($text) = @_;
        my $w = 0;
        $w += _char_width($_) for split //, $text;
        return $w;
    }

    # Return the terminal display width of a given UTF-8 byte sequence
    sub _display_width {
        my ($bytes) = @_;
        return 0 if $bytes eq '';
        return _display_width_chars(decode('UTF-8', $bytes, FB_DEFAULT));
    }

    # Return terminal (rows, cols); fallback if unable to obtain or 0.
    #
    # In some environments (verified on PowerMac G4: Mac OS X 10.4.0, build 8A428),
    # stty size may return "0 0" even when normal. Using 0 as columns causes _walk_position
    # to always return (0, 0), locking the cursor to column 0 (which caused Backspace to delete
    # the wrong character after arrow key editing). Values <= 0 are rejected as invalid.
    sub _term_size {
        my $wh = `stty size 2>/dev/null`;
        if ($wh =~ /^\s*(\d+)\s+(\d+)\s*$/ && $2 > 0) {
            my ($rows, $cols) = ($1, $2);
            return ($rows > 0 ? $rows : 24, $cols);
        }
        return (24, 80);
    }

    # Directly query terminal for current cursor row (1-based) via CPR
    # (\x1b[6n -> terminal replies \x1b[<row>;<col>R, a standard VT100 feature).
    # Always wait with a timeout to prevent hanging on unresponsive/broken environments
    # (terminals without CPR support, STDIN not a real terminal, etc.). If unobtainable,
    # return undef and caller proceeds with unknown position.
    #
    # Important: while waiting for CPR reply, the user may start pressing keys
    # (e.g. right after previous turn's output). As soon as a read byte deviates from the CPR
    # response format, all bytes read so far are restored to $pending_ref.
    # Strict format verification prevents swallowing genuine user input mistaken for CPR.
    sub _query_cursor_row {
        my ($pending_ref) = @_;
        print "\x1b[6n";
        my $deadline = time() + 0.3;
        my @consumed;

        my $read_raw = sub {
            my $remain = $deadline - time();
            return undef if $remain <= 0;
            my $rin = '';
            vec($rin, fileno(STDIN), 1) = 1;
            my $nfound = select(my $rout = $rin, undef, undef, $remain);
            return undef unless $nfound;
            my $ch;
            my $n = sysread(STDIN, $ch, 1);
            return (defined $n && $n > 0) ? $ch : undef;
        };
        my $give_up = sub {
            unshift @$pending_ref, @consumed;
            return undef;
        };

        my $c = $read_raw->();
        return $give_up->() unless defined $c;
        push @consumed, $c;
        return $give_up->() unless $c eq "\x1b";

        $c = $read_raw->();
        return $give_up->() unless defined $c;
        push @consumed, $c;
        return $give_up->() unless $c eq '[';

        my $row = '';
        while (1) {
            $c = $read_raw->();
            return $give_up->() unless defined $c;
            push @consumed, $c;
            last if $c eq ';';
            return $give_up->() unless $c =~ /[0-9]/;
            $row .= $c;
        }
        return $give_up->() if $row eq '';

        while (1) {
            $c = $read_raw->();
            return $give_up->() unless defined $c;
            push @consumed, $c;
            last if $c eq 'R';
            return $give_up->() unless $c =~ /[0-9]/;
        }

        return $row + 0;
    }

    # Same as _query_cursor_row, but also returns column number.
    # Used by _probe_terminal_size to measure actual terminal rows/cols via cursor movement.
    sub _query_cursor_pos {
        my ($pending_ref) = @_;
        print "\x1b[6n";
        my $deadline = time() + 0.3;
        my @consumed;

        my $read_raw = sub {
            my $remain = $deadline - time();
            return undef if $remain <= 0;
            my $rin = '';
            vec($rin, fileno(STDIN), 1) = 1;
            my $nfound = select(my $rout = $rin, undef, undef, $remain);
            return undef unless $nfound;
            my $ch;
            my $n = sysread(STDIN, $ch, 1);
            return (defined $n && $n > 0) ? $ch : undef;
        };
        my $give_up = sub {
            unshift @$pending_ref, @consumed;
            return (undef, undef);
        };

        my $c = $read_raw->();
        return $give_up->() unless defined $c;
        push @consumed, $c;
        return $give_up->() unless $c eq "\x1b";

        $c = $read_raw->();
        return $give_up->() unless defined $c;
        push @consumed, $c;
        return $give_up->() unless $c eq '[';

        my $row = '';
        while (1) {
            $c = $read_raw->();
            return $give_up->() unless defined $c;
            push @consumed, $c;
            last if $c eq ';';
            return $give_up->() unless $c =~ /[0-9]/;
            $row .= $c;
        }
        return $give_up->() if $row eq '';

        my $col = '';
        while (1) {
            $c = $read_raw->();
            return $give_up->() unless defined $c;
            push @consumed, $c;
            last if $c eq 'R';
            return $give_up->() unless $c =~ /[0-9]/;
            $col .= $c;
        }
        return $give_up->() if $col eq '';

        return ($row + 0, $col + 0);
    }

    # Measure real terminal rows and columns directly via cursor movement + CPR without relying on stty size.
    # Following the PowerMac G4 issue where stty size returned "0 0", hardware logs on PowerBook G4
    # revealed units returning row counts significantly smaller than the actual window (e.g. reporting 32 rows
    # for a 44-row window, triggering premature scroll-avoidance newlines when plenty of room remained).
    # stty size only returns the pty driver's value, which can desync from the terminal emulator window.
    # Instead, moving the cursor far off-screen (row 500, col 500) and querying its position causes the
    # terminal to clamp to the bottom-right corner (standard VT100 behavior), directly revealing the exact
    # dimensions. The cursor is then restored to its original position. Returns (measured rows, measured cols,
    # initial cursor row for $start_row). In environments where CPR does not respond, returns undef and caller
    # falls back to stty size.
    sub _probe_terminal_size {
        my ($pending_ref) = @_;
        my ($row0, $col0) = _query_cursor_pos($pending_ref);
        _debug_log(sprintf("[probe] initial pos: row=%s col=%s\n",
            defined $row0 ? $row0 : 'undef', defined $col0 ? $col0 : 'undef'));
        return (undef, undef, undef) unless defined $row0;
        # 4 digits (9999) caused unresponsive CPR on some older terminal implementations
        # that assumed fixed-digit parameters, so reduced to a safe 3 digits (500).
        # Real terminals rarely exceed 500 rows/cols, so 500 is more than enough for probing.
        print "\x1b[500;500H";
        my ($max_row, $max_col) = _query_cursor_pos($pending_ref);
        _debug_log(sprintf("[probe] after CUP 500;500: max_row=%s max_col=%s\n",
            defined $max_row ? $max_row : 'undef', defined $max_col ? $max_col : 'undef'));
        print "\x1b[${row0};${col0}H";
        return (undef, undef, $row0) unless defined $max_row;

        # Confirmed in hardware logs: rapid sequential prompts (e.g. pressing Enter on empty line)
        # can cause overlapping CPR replies if previous reply is still in-flight or delayed.
        # While strict syntax check might pass (matches ESC [ num ; num R), bogus values like "col 1"
        # could be adopted, causing disastrous character-by-character line wraps. Real terminal
        # dimensions are never that small, so obviously invalid values are treated as probe failures
        # and fallback to stty size.
        if ($max_row < 3 || $max_col < 10) {
            _debug_log(sprintf("[probe] measured size looks implausible (%dx%d), discarding\n",
                $max_row, $max_col));
            return (undef, undef, $row0);
        }
        return ($max_row, $max_col, $row0);
    }

    # Given decoded string $text and terminal width $cols, return (0-based row, 0-based col)
    # where cursor will be positioned after rendering.
    #
    # Rather than simply dividing total width by cols, characters are placed one by one.
    # When a fullwidth character (width 2) encounters only 1 remaining column at end of line,
    # the terminal does not render half the character; it wraps the entire character to next line
    # (leaving the last cell blank). Simple width division cannot account for this remainder,
    # which previously caused cursor drift and visual corruption during multibyte input.
    #
    # Terminal wrap uses deferred wrap (does not advance line until next character arrives),
    # so filling exactly $cols columns leaves cursor at the last column of that line.
    sub _walk_position {
        my ($text, $cols) = @_;
        return (0, 0) if $cols <= 0;
        my $row = 0;
        my $used = 0;  # Cells used in current row (0..cols)
        for my $ch (split //, $text) {
            my $w = _char_width($ch);
            if ($used + $w > $cols) {
                $row++;
                $used = 0;
            }
            $used += $w;
        }
        my $col = ($used == $cols) ? $cols - 1 : $used;
        return ($row, $col);
    }

    # Interactively read a single line while displaying prompt.
    # Supports arrow keys, Backspace, and (if use_history is true) up/down history recall.
    # Return value: entered line (raw bytes, without newline). undef on EOF (Ctrl-D).
    sub read_line_interactive {
        my ($prompt, $use_history, $color) = @_;
        $use_history = 1 unless defined $use_history;
        $color = '' unless defined $color;

        my $orig_stty = `stty -g`;
        chomp $orig_stty;
        my ($term_rows, $term_cols) = _term_size();
        # Without -opost, output post-processing (especially ocrnl) may remain active,
        # turning \r used for redraw into a newline and creating a new line on every keystroke.
        system('stty', 'raw', '-echo', '-opost');

        # Pushback queue for bytes read ahead by mistake, returned to next loop iteration.
        # Used when a byte thought to be part of a multibyte sequence lacks continuation format (10xxxxxx),
        # or when CPR query turns out to be genuine user keystrokes. Kept across the entire read_line_interactive
        # call, so defined before CPR query.
        my @pending;

        # Continuing input near the bottom of the screen can cause redraws to scroll the terminal,
        # burning intermediate input states into scrollback history (ANSI clear only affects visible area).
        # We query cursor start row via CPR, and only when $redraw detects content will exceed
        # the bottom row do we insert a newline to avoid this (see $redraw below). Normal short responses
        # insert no extra newlines. When CPR is unsupported/unresponsive, $start_row remains undef and
        # behavior is unchanged.
        #
        # Also re-probe $term_rows and $term_cols using CPR rather than relying solely on stty size
        # (see _probe_terminal_size). Overwrite only when successfully probed; otherwise fall back
        # to stty size values.
        my ($probed_rows, $probed_cols, $start_row) = _probe_terminal_size(\@pending);
        if (defined $probed_rows) {
            _debug_log(sprintf("[probe] using measured size: %dx%d (stty said %dx%d)\n",
                $probed_rows, $probed_cols, $term_rows, $term_cols));
            $term_rows = $probed_rows;
            $term_cols = $probed_cols;
        } else {
            _debug_log(sprintf("[probe] measurement failed, falling back to stty size: %dx%d\n",
                $term_rows, $term_cols));
        }

        my $buf = '';                    # Raw bytes
        my $pos = 0;                     # Cursor position (in bytes, always at character boundary)
        my $hist_idx = scalar(@HISTORY); # History cursor (end of array = new input in progress)
        my $saved_buf = '';              # Stashed input prior to traversing history

        # Leading newline in $prompt (e.g. "\nUser> ") is only used on initial print.
        # Including it in redraws would insert newlines on every keystroke.
        (my $redraw_prompt = $prompt) =~ s/^\n+//;

        # Initial value is the number of rows occupied by redraw_prompt alone (buf empty).
        my $rows_used = (_walk_position($redraw_prompt, $term_cols))[0] + 1;

        # Row offset of cursor from top of prompt block (0-based).
        # Needed separately from $rows_used (total block height) because left/right arrows
        # can move cursor to an earlier row in multiline input. In initial state (empty buf),
        # cursor is at the end of redraw_prompt.
        my $cursor_display_row = (_walk_position($redraw_prompt, $term_cols))[0];

        my $redraw = sub {
            # $buf is raw UTF-8 bytes. Since STDOUT has :encoding(UTF-8) layer,
            # decode to Perl string before passing, to prevent double-encoding garble.
            my $text   = decode('UTF-8', $buf, FB_DEFAULT);
            my $before = decode('UTF-8', substr($buf, 0, $pos), FB_DEFAULT);
            my $full_text   = $redraw_prompt . $text;
            my $full_width  = _display_width_chars($full_text);
            my $cursor_width = _display_width_chars($redraw_prompt . $before);
            my $end_row = (_walk_position($full_text, $term_cols))[0];

            # Debug logging: records escape sequences sent and underlying calculations.
            # Only active when CLAUDE_DEBUG_INPUT is set. Comparing sent commands with screen
            # output helps determine whether an issue is calculation logic or terminal emulation.
            _debug_log(sprintf(
                "[redraw] term_cols=%d pos=%d buf_hex=%s rows_used_before=%d full_width=%d cursor_width=%d end_row=%d\n",
                $term_cols, $pos, unpack('H*', $buf), $rows_used, $full_width, $cursor_width, $end_row
            ));

            # Lazy bottom-of-screen avoidance: insert newline only at the exact moment
            # content is about to exceed terminal bottom row (proactively reserving space on every
            # prompt would leave empty blank lines in scrollback for short inputs).
            if (defined $start_row && $start_row + $end_row >= $term_rows) {
                my $overflow = $start_row + $end_row - $term_rows + 1;
                _debug_log(sprintf("[redraw] lazy headroom: send %d newline(s), start_row was %d\n",
                    $overflow, $start_row));
                print "\n" x $overflow, "\r";

                # Send newlines to terminal. Since at bottom row, terminal scrolls.
                # Amount to move back up must include not only $cursor_display_row but also $overflow rows
                # just sent by newlines to return to block start.
                my $back = $cursor_display_row + $overflow;
                if ($back > 0) {
                    print "\x1b[" . $back . "A";
                }
                my $measured = _query_cursor_row(\@pending);
                if (defined $measured) {
                    $start_row = $measured;
                } else {
                    # Fallback estimation for environments where CPR is unavailable
                    $start_row -= $overflow;
                    $start_row = 1 if $start_row < 1;
                }
                _debug_log(sprintf("[redraw] lazy headroom: start_row now %d (measured=%s)\n",
                    $start_row, defined $measured ? $measured : 'undef'));
                # Mark cursor as already at block head to prevent duplicate repositioning below.
                $cursor_display_row = 0;
            }

            # Move cursor up by $cursor_display_row (where cursor actually was in previous redraw)
            # and clear from there to end of screen. Must use $cursor_display_row rather than $rows_used
            # because arrow keys may leave cursor in an earlier row; using $rows_used would move
            # too far up and erase previous conversation history above prompt.
            if ($cursor_display_row > 0) {
                _debug_log(sprintf("[redraw] send: CUU %d\n", $cursor_display_row));
                print "\x1b[" . $cursor_display_row . "A";
            }
            # When cursor is in the middle of a line, render text after cursor in reverse video (SGR 7).
            # Helps visually distinguish cursor position on vintage LCD/CRT displays where blinking
            # hardware cursor can be hard to see. SGR control codes have zero width, so layout calculations
            # remain unaffected.
            if ($cursor_width < $full_width) {
                my $after = substr($text, length($before));
                _debug_log(sprintf("[redraw] send: CR + ED0 + text=%s (reverse-video tail after cursor)\n",
                    unpack('H*', encode('UTF-8', $full_text))));
                print "\r\x1b[0J", $color, $redraw_prompt, $before, "\x1b[7m", $after, "\x1b[0m", $color;
            } else {
                _debug_log(sprintf("[redraw] send: CR + ED0 + text=%s\n", unpack('H*', encode('UTF-8', $full_text))));
                print "\r\x1b[0J", $color, $full_text;
            }

            $rows_used = $end_row + 1;
            _debug_log(sprintf("[redraw] rows_used_after=%d\n", $rows_used));

            if ($cursor_width < $full_width) {
                my ($cur_row, $cur_col) = _walk_position($redraw_prompt . $before, $term_cols);
                _debug_log(sprintf("[redraw] cursor not at end: cur_row=%d cur_col=%d\n", $cur_row, $cur_col));
                if ($end_row > $cur_row) {
                    _debug_log(sprintf("[redraw] send: CUU %d\n", $end_row - $cur_row));
                    print "\x1b[" . ($end_row - $cur_row) . "A";
                }
                _debug_log(sprintf("[redraw] send: CHA %d\n", $cur_col + 1));
                print "\x1b[" . ($cur_col + 1) . "G";
                $cursor_display_row = $cur_row;
            } else {
                $cursor_display_row = $end_row;
            }
        };

        if ($color) {
            if ($prompt =~ /^(\n*)(.*)$/s) {
                print $1, $color, $2;
            } else {
                print $color, $prompt;
            }
        } else {
            print $prompt;
        }
        _debug_log("=== read_line_interactive start ===\n");

        # (@pending queue is shared with CPR query and was defined at function start)
        my $read_one_byte = sub {
            return shift @pending if @pending;
            my $ch;
            my $n = sysread(STDIN, $ch, 1);
            return (defined $n && $n > 0) ? $ch : undef;
        };
        # Mac OS X Tiger Terminal.app sometimes prefixes bytes with 0x16 (Ctrl-V, traditionally LNEXT)
        # when delivering text confirmed via IME. Since this program runs in raw mode and does not interpret
        # LNEXT, unhandled 0x16 would corrupt UTF-8 strings. We skip 0x16 and treat subsequent byte as raw data.
        my $last_was_lnext = 0;   # Was the previous byte 0x16 (LNEXT)?
        my $read_byte = sub {
            my $ch = $read_one_byte->();
            if (defined $ch && $ch eq "\x16") {
                $ch = $read_one_byte->();
                $last_was_lnext = 1;
                _debug_log(sprintf("  (LNEXT 0x16 skipped, next byte: %s)\n",
                    defined $ch ? sprintf('%02x', ord($ch)) : 'eof'));
            }
            else {
                $last_was_lnext = 0;
            }
            return $ch;
        };

        my $result;
        RAW_LOOP: while (1) {
            my $ch = $read_byte->();
            if (!defined $ch) {
                _debug_log("EOF\n");
                print $COLOR_RESET if $color;
                $result = undef;  # EOF (Ctrl-D)
                last RAW_LOOP;
            }
            my $b = ord($ch);
            _debug_log(sprintf("byte: %02x (%s)\n", $b, ($b >= 0x20 && $b < 0x7f) ? chr($b) : ''));

            if ($b == 13 || $b == 10) {       # Enter
                # A newline wrapped in 0x16 (LNEXT) comes from IME confirmation rather than an intentional
                # Enter keypress to submit. Terminal.app on Tiger sends confirmed text byte-by-byte with 0x16;
                # confirming during candidate selection could trigger premature submission. Wrapped newlines
                # are discarded; plain Enter (without 0x16) submits normally.
                if ($last_was_lnext) {
                    _debug_log("-> newline via LNEXT: treated as IME-commit, not submit\n");
                    next RAW_LOOP;
                }
                _debug_log(sprintf("-> ENTER, buf hex=%s\n", unpack('H*', $buf)));
                print $COLOR_RESET if $color;
                print "\r\n";
                $result = $buf;
                last RAW_LOOP;
            }
            elsif ($b == 3) {                  # Ctrl-C: cancel line, treat as empty
                print $COLOR_RESET if $color;
                print "\r\n";
                $result = '';
                last RAW_LOOP;
            }
            elsif ($b == 4) {                  # Ctrl-D: EOF on empty line
                if ($buf eq '') {
                    print $COLOR_RESET if $color;
                    $result = undef;
                    last RAW_LOOP;
                }
            }
            elsif ($b == 127 || $b == 8) {      # Backspace
                if ($pos > 0) {
                    my $start = $pos - 1;
                    $start-- while $start > 0 && (ord(substr($buf, $start, 1)) & 0xC0) == 0x80;
                    substr($buf, $start, $pos - $start, '');
                    $pos = $start;
                    $redraw->();
                }
            }
            elsif ($b == 27) {                  # ESC: cursor keys, etc.
                my $c2 = $read_byte->();
                next RAW_LOOP unless defined $c2;
                if ($c2 eq '[') {
                    my $c3 = $read_byte->();
                    next RAW_LOOP unless defined $c3;
                    if ($c3 eq 'C') {            # →
                        if ($pos < length($buf)) {
                            $pos += _utf8_char_len(substr($buf, $pos, 1));
                            $redraw->();
                        }
                    }
                    elsif ($c3 eq 'D') {         # ←
                        if ($pos > 0) {
                            my $start = $pos - 1;
                            $start-- while $start > 0 && (ord(substr($buf, $start, 1)) & 0xC0) == 0x80;
                            $pos = $start;
                            $redraw->();
                        }
                    }
                    elsif ($use_history && $c3 eq 'A') {  # Up arrow: go back in history
                        if ($hist_idx > 0) {
                            $saved_buf = $buf if $hist_idx == @HISTORY;
                            $hist_idx--;
                            $buf = $HISTORY[$hist_idx];
                            $pos = length($buf);
                            $redraw->();
                        }
                    }
                    elsif ($use_history && $c3 eq 'B') {  # Down arrow: go forward in history
                        if ($hist_idx < @HISTORY) {
                            $hist_idx++;
                            $buf = ($hist_idx == @HISTORY) ? $saved_buf : $HISTORY[$hist_idx];
                            $pos = length($buf);
                            $redraw->();
                        }
                    }
                    elsif ($c3 =~ /[0-9;]/) {
                        # Format: ESC [ <digits and semicolons...> <terminator>.
                        # Collect digits/semicolons until terminator.
                        my $params = $c3;
                        my $final;
                        while (1) {
                            my $cx = $read_byte->();
                            last unless defined $cx;
                            if ($cx =~ /[0-9;]/) { $params .= $cx; next; }
                            $final = $cx;
                            last;
                        }
                        if (defined $final && $final eq '~' && $params eq '3') {
                            # Delete key (ESC [ 3 ~)
                            if ($pos < length($buf)) {
                                substr($buf, $pos, _utf8_char_len(substr($buf, $pos, 1)), '');
                                $redraw->();
                            }
                        }
                        # Discard everything else (especially $final eq 'R' = delayed CPR cursor position report).
                        # When prompts start in rapid succession, delayed CPR responses (e.g. "\x1b[32;59R")
                        # could arrive mixed with input. Consuming the whole CSI sequence here prevents corrupting the buffer.
                        _debug_log(sprintf("[input] swallowed CSI: ESC [ %s %s\n",
                            $params, defined $final ? $final : '(eof)'));
                    }
                }
            }
            else {                               # Regular character (raw UTF-8 bytes)
                # Wait until all bytes of a multibyte character arrive before adding to buffer and redrawing,
                # otherwise decode() will turn incomplete sequences into replacement characters. If subsequent
                # byte is not a valid UTF-8 continuation byte (10xxxxxx), restore it to pending queue.
                my $need = _utf8_char_len($ch) - 1;
                my $char = $ch;
                while ($need > 0) {
                    my $cont = $read_byte->();
                    last unless defined $cont;
                    _debug_log(sprintf("  continuation byte: %02x\n", ord($cont)));
                    if ((ord($cont) & 0xC0) != 0x80) {
                        unshift @pending, $cont;
                        last;
                    }
                    $char .= $cont;
                    $need--;
                }
                substr($buf, $pos, 0) = $char;
                $pos += length($char);

                # Fast path: when cursor is at end of line (append only) and this character causes
                # neither line wrap nor scroll-avoidance newline, print the character directly rather than
                # redrawing the entire line. Full redraw on every keystroke causes noticeable flicker on slow
                # vintage hardware (reported on PowerBook G4). Redraw only on operations that shift positions
                # (wrap, insertion, arrows, history, Backspace).
                my $fast = 0;
                if ($pos == length($buf)) {
                    my $new_full = $redraw_prompt . decode('UTF-8', $buf, FB_DEFAULT);
                    my ($nr, $nc) = _walk_position($new_full, $term_cols);
                    if ($nr == $rows_used - 1                    # Row count does not increase
                        && $nc <= $term_cols - 2                 # Not waiting for deferred line wrap
                        && !(defined $start_row
                             && $start_row + $nr >= $term_rows)) # No scroll avoidance needed
                    {
                        print decode('UTF-8', $char, FB_DEFAULT);
                        $cursor_display_row = $nr;
                        _debug_log(sprintf("[fast] append 1 char, pos=%d nc=%d\n", $pos, $nc));
                        $fast = 1;
                    }
                }
                $redraw->() unless $fast;
            }
        }

        system('stty', $orig_stty) if defined $orig_stty && $orig_stty ne '';
        print $COLOR_RESET if $color;

        if ($use_history && defined $result && $result ne '') {
            push @HISTORY, $result;
        }
        return $result;
    }
}

sub run_tool {
    my ($name, $input) = @_;

    # The return value of run_tool is not shown directly to user, but sent to the model
    # as tool_result log. The user only directly sees the confirm() prompt.
    if ($name eq 'read_file') {
        my $path = $input->{path};
        open(my $fh, '<:encoding(UTF-8)', $path) or return "Error: cannot open $path: $!";
        local $/;
        my $content = <$fh>;
        close $fh;
        return $content;
    }
    elsif ($name eq 'write_file') {
        my $path = $input->{path};
        unless (confirm_tool("Write to file '$path'?")) {
            return "Cancelled by user.";
        }
        open(my $fh, '>:encoding(UTF-8)', $path) or return "Error: cannot write $path: $!";
        print $fh $input->{content};
        close $fh;
        return "Write complete: $path";
    }
    elsif ($name eq 'list_dir') {
        my $path = $input->{path} || '.';
        opendir(my $dh, $path) or return "Error: cannot open $path: $!";
        my @entries = sort grep { $_ ne '.' && $_ ne '..' } readdir($dh);
        closedir $dh;
        return join("\n", @entries);
    }
    elsif ($name eq 'run_shell') {
        my $command = $input->{command};
        unless (confirm_tool("Run this command: $command")) {
            return "Cancelled by user.";
        }
        my $output = `$command 2>&1`;
        return $output eq '' ? '(no output)' : $output;
    }
    else {
        return "Unknown tool: $name";
    }
}

# ------------------------------------------------------------------
# Conversation loop
# ------------------------------------------------------------------
unless (caller) {
my @messages;

print "\e[7mCode AI-Agent\e[0m\n";
{
    my $where = '';
    if ($PROVIDER eq 'openai' && $API_URL =~ m{^https?://([^/]+)}) {
        $where = " @ $1";
    }
    print "[$PROVIDER / $MODEL$where]\n";
}
print "Hello. (Type 'exit' or Ctrl-D to quit. Switch model with /models. Switch AI with /claude /gemini /openai. Mode with /auto /manual. Type /help for help)\n";

while (1) {
    my $input = read_line_interactive("\nUser> ", 1, $COLOR_USER);
    last unless defined $input;
    # Decode to UTF-8 after full line (raw bytes) is read
    $input = decode('UTF-8', $input, FB_DEFAULT);
    next if $input eq '';
    last if $input eq 'exit';

    if ($input eq '/help') {
        show_help();
        next;
    }

    if ($input eq '/models') {
        handle_models_command();
        next;
    }

    if ($input eq '/auto') {
        handle_auto_command();
        next;
    }

    if ($input eq '/manual') {
        handle_manual_command();
        next;
    }

    if ($input eq '/claude' || $input eq '/gemini' || $input eq '/openai') {
        my $target = $input eq '/claude' ? 'anthropic'
                   : $input eq '/gemini' ? 'gemini'
                   :                       'openai';
        if ($target eq $PROVIDER) {
            print "\nAlready on [$PROVIDER / $MODEL].\n";
        }
        elsif ($target eq 'openai' && !$ENV{OPENAI_BASE_URL}) {
            # OpenAI requires a base URL rather than just an API key.
            # More reliable to set environment variables and restart.
            print "\nSwitching to an OpenAI-compatible server needs OPENAI_BASE_URL set.\n";
            print "e.g. export OPENAI_BASE_URL=http://192.168.1.50:8080/v1\n";
            print "(also OPENAI_API_KEY and CLAUDE_MODEL if needed)\n";
            print "Set it and restart. Staying on [$PROVIDER / $MODEL] for now.\n";
        }
        else {
            eval { configure_provider($target) };
            if ($@ && $target eq 'openai') {
                print "\nCould not switch: $@";
            }
            elsif ($@) {
                # If key is missing, prompt interactively.
                # Cancel with Esc or Ctrl+C to stay on current provider.
                my $key_name = $target eq 'gemini' ? 'GEMINI_API_KEY' : 'ANTHROPIC_API_KEY';
                my $key = read_secret_or_cancel(
                    "\n$key_name is not set yet. Please enter it (Esc or Ctrl+C to cancel)\n> "
                );
                if (!defined $key || $key eq '') {
                    print "\nCancelled. Staying on [$PROVIDER / $MODEL].\n";
                }
                else {
                    $ENV{$key_name} = $key;
                    eval { configure_provider($target) };
                    if ($@) {
                        print "\nStill could not switch: $@";
                    }
                    else {
                        print "\nSwitched to [$PROVIDER / $MODEL]. The conversation so far carries over.\n";
                        if (confirm("Save this key to $ENV_FILE_PATH so you don't need to enter it again?")) {
                            if (open(my $ef, '>>', $ENV_FILE_PATH)) {
                                print $ef "export $key_name=$key\n";
                                close $ef;
                                chmod 0600, $ENV_FILE_PATH;
                                print "Saved.\n";
                            }
                            else {
                                print "Could not save (cannot write $ENV_FILE_PATH).\n";
                            }
                        }
                    }
                }
            }
            else {
                print "\nSwitched to [$PROVIDER / $MODEL]. The conversation so far carries over.\n";
            }
        }
        next;
    }

    push @messages, { role => 'user', content => $input };

    while (1) {
        my $body = build_request(\@messages, \@TOOLS, $SYSTEM_PROMPT);
        my $resp = call_api($API_URL, build_headers(), MiniJSON::encode($body));

        my @content_blocks = eval { parse_response($resp) };
        if ($@) {
            print $@;
            last;
        }
        push @messages, { role => 'assistant', content => \@content_blocks };

        my @tool_results;
        for my $block (@content_blocks) {
            if ($block->{type} eq 'text') {
                print "\n${COLOR_MODEL}Code AI> ";
                slow_print("$block->{text}\n");
                print $COLOR_RESET;
            }
            elsif ($block->{type} eq 'tool_use') {
                print "\n[tool_use] $block->{name}(" . MiniJSON::encode($block->{input}) . ")\n";
                my $result = run_tool($block->{name}, $block->{input});
                push @tool_results, {
                    type => 'tool_result',
                    tool_use_id => $block->{id},
                    name => $block->{name},
                    content => $result,
                };
            }
        }

        if (@tool_results) {
            push @messages, { role => 'user', content => \@tool_results };
            next; # Send tool result and call API again
        }

        last; # If no tool_use, this turn is finished
    }
}

print "\nGoodbye.\n";
}

1;
