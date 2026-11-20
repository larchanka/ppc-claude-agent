
# --- curl invocation (TLS 1.2/1.3 toolchain curl) ---
sub call_api {
    # $headers is an arrayref of header strings (e.g. "x-api-key: ...").
    # Thin transport layer that takes URL/headers from outside per provider;
    # this sub itself has no knowledge of whether it's Anthropic or Gemini.
    my ($url, $headers, $body_json, $method) = @_;
    $method = defined $method ? uc($method) : 'POST';
    my $has_body = ($method ne 'GET' && defined $body_json) ? 1 : 0;

    my $tmp_req    = "/tmp/code-agent-req-$$.json";
    my $tmp_resp   = "/tmp/code-agent-resp-$$.json";
    my $tmp_config = "/tmp/code-agent-curlcfg-$$.txt";
    my $tmp_status = "/tmp/code-agent-status-$$.txt";

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

    my $start_time = time();
    my $http_code = '';
    my $is_tty = defined $ENV{CLAUDE_TEST_TTY} ? $ENV{CLAUDE_TEST_TTY} : -t STDOUT;
    my $use_live_timer = ($is_tty && $has_body) ? 1 : 0;

    if ($use_live_timer) {
        my $pid = fork();
        if (!defined $pid) {
            # fork failed: fall back safely to synchronous execution
            $http_code = `@{[quote($CURL)]} -K @{[quote($tmp_config)]}`;
        }
        elsif ($pid == 0) {
            # child: redirect stdout to status file for curl's write-out http code
            open(STDOUT, '>', $tmp_status) or POSIX::_exit(1);
            if (-x $CURL) {
                exec($CURL, '-K', $tmp_config);
            }
            else {
                exec('/bin/sh', '-c', quote($CURL) . ' -K ' . quote($tmp_config));
            }
            POSIX::_exit(127);
        }
        else {
            # parent: display live ticking timer
            local $| = 1;
            my $last_sec = -1;
            while (1) {
                my $kid = waitpid($pid, WNOHANG);
                if ($kid == $pid || $kid == -1) {
                    last;
                }
                my $elapsed = int(time() - $start_time);
                $elapsed = 1 if $elapsed < 1;
                if ($elapsed != $last_sec) {
                    print "\r\033[K" . format_thinking_status($elapsed);
                    $last_sec = $elapsed;
                }
                select(undef, undef, undef, 0.2);
            }
            if (-f $tmp_status) {
                if (open(my $sf, '<', $tmp_status)) {
                    $http_code = <$sf>;
                    close $sf;
                }
                unlink $tmp_status;
            }
        }
    }
    else {
        # Non-TTY or disabled: synchronous execution
        $http_code = `@{[quote($CURL)]} -K @{[quote($tmp_config)]}`;
    }

    $http_code = '' unless defined $http_code;
    chomp $http_code;
    $http_code =~ s/^\s+|\s+$//g;

    $LAST_API_ELAPSED = int(time() - $start_time);
    $LAST_API_ELAPSED = 1 if $LAST_API_ELAPSED < 1;

    unlink $tmp_req if $has_body;
    unlink $tmp_config;
    unlink $tmp_status if -e $tmp_status;

    # For the same reason as STDIN (see comments at top), we do not use the
    # :encoding(UTF-8) layer here. In Perl 5.8.6, PerlIO :encoding(UTF-8) can split
    # multibyte characters across read buffer boundaries when reading responses
    # containing multibyte characters, causing "utf8 does not map to Unicode"
    # warnings and text corruption. Reading all raw bytes first and decoding them
    # together at the end avoids this issue.
    my $resp_body_bytes = '';
    if (-f $tmp_resp) {
        if (open(my $rf, '<', $tmp_resp)) {
            local $/;
            $resp_body_bytes = <$rf>;
            close $rf;
        }
        unlink $tmp_resp;
    }
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
