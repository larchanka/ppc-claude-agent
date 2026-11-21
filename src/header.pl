#!/usr/bin/perl
# code-agent.pl — Self-contained Claude API agent for iBook G4
# (Mac OS X 10.4 Tiger, Perl 5.8.6). Has no external CPAN module dependencies.
#
# Prerequisite: /usr/local/code-toolchain/bin/curl (with TLS 1.2/1.3 support),
#               built via ~/code-build/build/remote-build-*.sh, must be available.
#
# Usage:
#   export ANTHROPIC_API_KEY=sk-ant-...
#   perl code-agent.pl

use strict;
use warnings;
use utf8;
use Encode qw(decode encode FB_DEFAULT);
use POSIX qw(WNOHANG);

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

# --- Configuration ---
my $CURL   = $ENV{CLAUDE_CURL}   || (-x '/usr/local/code-toolchain/bin/curl' ? '/usr/local/code-toolchain/bin/curl' : '/usr/local/claude-toolchain/bin/curl');
my $CACERT = $ENV{CLAUDE_CACERT} || (-f '/usr/local/code-toolchain/cacert.pem' ? '/usr/local/code-toolchain/cacert.pem' : '/usr/local/claude-toolchain/cacert.pem');
my $MAX_TOKENS = 4096;

# Resolves the environment file path.
# Prefers ~/.code-agent-env, falling back to legacy ~/.claude-agent-env if it exists.
sub get_env_file_path {
    my $home = $ENV{HOME} || '.';
    my $primary = "$home/.code-agent-env";
    my $legacy  = "$home/.claude-agent-env";
    return $legacy if !-e $primary && -e $legacy;
    return $primary;
}

# Loads environment variables from an env file (defaulting to get_env_file_path()).
# Skips lines that don't match or variables already present in %ENV.
sub load_env_file {
    my ($file) = @_;
    $file = get_env_file_path() unless defined $file;
    return unless -f $file;
    if (open(my $fh, '<', $file)) {
        while (my $line = <$fh>) {
            chomp $line;
            if ($line =~ /^\s*(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)=(.*)$/) {
                my ($k, $v) = ($1, $2);
                $v =~ s/^\s+|\s+$//g;
                $v =~ s/^["'](.*)["']$/$1/;
                $ENV{$k} = $v unless exists $ENV{$k};
            }
        }
        close $fh;
    }
}

# Theme-safe ANSI attributes (zero hardcoded colors; adapts to Terminal profile)
our $COLOR_RESET = "\x1b[0m";
our $COLOR_USER  = "\x1b[34m";   # Default foreground (avoids \e[2m dim which blends into background on Leopard/Tiger)
our $COLOR_MODEL = "\x1b[35m";   # Bold (high contrast using profile's bold setting)
our $COLOR_DIM   = "\x1b[33m";   # Dim (for compact tool invocation summaries)
if (!-t STDOUT || exists $ENV{NO_COLOR}) {
    $COLOR_RESET = '';
    $COLOR_USER  = '';
    $COLOR_MODEL = '';
    $COLOR_DIM   = '';
}

sub cursor_hide {
    my $is_tty = defined $ENV{CLAUDE_TEST_TTY} ? $ENV{CLAUDE_TEST_TTY} : -t STDOUT;
    print "\x1b[?25l" if $is_tty;
}

sub cursor_show {
    my $is_tty = defined $ENV{CLAUDE_TEST_TTY} ? $ENV{CLAUDE_TEST_TTY} : -t STDOUT;
    print "\x1b[?25h" if $is_tty;
}

END {
    cursor_show();
}

# Provider switching. CLAUDE_PROVIDER=gemini uses the Gemini API free tier with no
# credit card required (default is Anthropic). Can also be switched during conversation
# via /claude or /gemini (see configure_provider below).
my ($PROVIDER, $API_KEY, $MODEL, $API_URL, $ANTHROPIC_VERSION);

# Application version.
our $VERSION = '1.0.0';

# Autonomous tool execution mode. When enabled, tools that normally require
# confirmation (write_file, run_shell) execute immediately without prompting.
our $AUTO_MODE = $ENV{CLAUDE_AUTO_MODE} ? 1 : 0;

# Active conversation session and monotonic ID sequence counter.
our $CURRENT_SESSION = undef;
our $SESSION_COUNTER = 0;
our $LAST_API_ELAPSED = 0;

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


our $SYSTEM_PROMPT = <<'EOS';
You are a lightweight coding assistant running in the terminal of a
PowerPC iBook G4 (Mac OS X 10.4 Tiger). You have five tools available:
read_file, write_file, edit_file, list_dir, and run_shell. Use them to
read, create, edit files and run commands in the user's working directory.
Keep replies concise, and always reply in the same language the user wrote
in (if they write in Japanese, reply in Japanese; if English, reply in
English; and so on for other languages).

Tool usage guidelines:
- read_file: Reads file contents. Supports optional 1-based inclusive
  `start_line` and `end_line` parameters. Use them to inspect specific
  slices or navigate large files efficiently. Omit to read the full file.
- edit_file: Replaces a range of lines (`start_line` to `end_line`,
  1-based inclusive) with new `content`. Prefer `edit_file` over
  `write_file` for updating existing files to avoid rewriting entire files.
  To insert content without deleting lines, set `end_line = start_line - 1`.
  To delete lines, provide an empty string `""` as `content`.
- write_file: Creates a new file or completely overwrites an existing file.
  Use primarily for creating new files.
- list_dir: Lists entries in a directory.
- run_shell: Executes a shell command and captures output.

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

# Reads an AGENTS.md instructions file safely and decodes it from UTF-8.
# Returns empty string if the file is missing, unreadable, or not a regular file.
sub read_agents_file {
    my ($path) = @_;
    return '' unless defined $path && -f $path;
    open(my $fh, '<', $path) or return '';
    local $/;
    my $raw = <$fh>;
    close $fh;
    return '' unless defined $raw;
    my $content = decode('UTF-8', $raw, FB_DEFAULT);
    return defined $content ? $content : '';
}

# Discovers global (~/.agents/AGENTS.md) and local (./AGENTS.md) instructions.
# Deduplicates when both paths point to the exact same physical file via stat() dev/ino.
# Returns formatted markdown sections or empty string if no instructions found.
sub get_agents_context {
    my ($home_dir, $cwd) = @_;
    $home_dir = $ENV{HOME} if !defined $home_dir || $home_dir eq '';
    $home_dir = '.' if !defined $home_dir || $home_dir eq '';
    $cwd = '.' if !defined $cwd || $cwd eq '';

    my $global_path = "$home_dir/.agents/AGENTS.md";
    my $local_path  = "$cwd/AGENTS.md";

    my ($g_dev, $g_ino) = -f $global_path ? (stat($global_path))[0, 1] : ();
    my ($l_dev, $l_ino) = -f $local_path  ? (stat($local_path))[0, 1]  : ();

    my $same_file = (defined $g_dev && defined $l_dev && $g_dev == $l_dev && $g_ino == $l_ino) ? 1 : 0;

    my @sections;

    my $global_content = read_agents_file($global_path);
    $global_content =~ s/^\s+|\s+$//g;
    if (length $global_content) {
        push @sections, "# Global Instructions (~/.agents/AGENTS.md)\n\n$global_content";
    }

    if (!$same_file) {
        my $local_content = read_agents_file($local_path);
        $local_content =~ s/^\s+|\s+$//g;
        if (length $local_content) {
            push @sections, "# Project Instructions (AGENTS.md)\n\n$local_content";
        }
    }

    return join("\n\n", @sections);
}

# Composes base system prompt with discovered AGENTS.md instructions.
# Returns base prompt unchanged if context is empty.
sub get_effective_system_prompt {
    my ($base_prompt, $home_dir, $cwd) = @_;
    $base_prompt = $SYSTEM_PROMPT unless defined $base_prompt;
    my $context = get_agents_context($home_dir, $cwd);
    return $base_prompt unless length $context;

    my $prompt = $base_prompt;
    $prompt =~ s/\s+$//;
    return $prompt . "\n\n" . $context . "\n";
}

