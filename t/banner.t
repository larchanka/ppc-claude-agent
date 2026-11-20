#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 9;

use File::Basename qw(dirname);
use Cwd qw(abs_path);

my $root_dir = abs_path(dirname(__FILE__) . '/..');
$ENV{CLAUDE_CURL} = "$root_dir/t/mock_curl.pl";
$ENV{CLAUDE_CACERT} = "$root_dir/cacert.pem";

system($^X, "$root_dir/build.pl") unless -f "$root_dir/code-agent.pl";
require "$root_dir/code-agent.pl";

our ($PROVIDER, $MODEL, $AUTO_MODE, $API_URL);
our ($COLOR_DIM, $COLOR_MODEL, $COLOR_RESET);

# Test 1: show_banner output with default provider and model
{
    $ENV{GEMINI_API_KEY} = "AIzaSyTestKey123";
    delete $ENV{CLAUDE_MODEL};
    configure_provider('gemini');
    set_auto_mode(0);

    my $out = "";
    open my $fh, ">", \$out or die "Cannot open scalar fh: $!";
    show_banner($fh);
    close $fh;

    like($out, qr/_____/s, "Banner contains ASCII art header");
    like($out, qr/\[gemini \/ gemini-3\.5-flash-lite\]  mode: manual/, "Status line includes provider, model, and manual mode");
    like($out, qr/Type \/help for commands, \/models to switch model\./, "Includes help instructions");
}

# Test 2: show_banner with auto mode
{
    $ENV{ANTHROPIC_API_KEY} = "sk-ant-test";
    $ENV{CLAUDE_MODEL} = "claude-3-5-sonnet";
    configure_provider('anthropic');
    set_auto_mode(1);

    my $out = "";
    open my $fh, ">", \$out or die "Cannot open scalar fh: $!";
    show_banner($fh);
    close $fh;

    like($out, qr/\[anthropic \/ claude-3-5-sonnet\]  mode: auto/, "Status line reflects auto mode");
}

# Test 3: show_banner with openai and endpoint host
{
    $ENV{OPENAI_BASE_URL} = "http://192.168.1.50:8080/v1";
    $ENV{CLAUDE_MODEL} = "llama3";
    configure_provider('openai');
    set_auto_mode(0);

    my $out = "";
    open my $fh, ">", \$out or die "Cannot open scalar fh: $!";
    show_banner($fh);
    close $fh;

    like($out, qr/\[openai \/ llama3 \@ 192\.168\.1\.50:8080\]  mode: manual/, "OpenAI host displayed in status line");
}

# Test 4: handles undefined values gracefully
{
    my $out = "";
    open my $fh, ">", \$out or die "Cannot open scalar fh: $!";
    show_banner($fh);
    close $fh;

    like($out, qr/mode: (?:manual|auto)/, "Handles banner status display");
}

# Test 5: verify ASCII art bounds (lines fit within 80 columns)
{
    my $out = "";
    open my $fh, ">", \$out or die "Cannot open scalar fh: $!";
    show_banner($fh);
    close $fh;

    my $max_len = 0;
    for my $line (split /\n/, $out) {
        my $clean = $line;
        $clean =~ s/\x1b\[[0-9;]*m//g;
        $max_len = length($clean) if length($clean) > $max_len;
    }
    cmp_ok($max_len, '<=', 80, "All banner lines fit comfortably within 80 columns");
}

# Test 6: ANSI color emission for yellow "Code" and magenta "Agent"
{
    local $COLOR_DIM   = "\x1b[33m";
    local $COLOR_MODEL = "\x1b[35m";
    local $COLOR_RESET = "\x1b[0m";

    my $out = "";
    open my $fh, ">", \$out or die "Cannot open scalar fh: $!";
    show_banner($fh);
    close $fh;

    like($out, qr/\x1b\[33m\s*_____.*?\x1b\[35m/s, "Banner emits yellow for Code and magenta for Agent");
}

# Test 7: Graceful degradation when colors are empty/disabled
{
    local $COLOR_DIM   = "";
    local $COLOR_MODEL = "";
    local $COLOR_RESET = "";

    my $out = "";
    open my $fh, ">", \$out or die "Cannot open scalar fh: $!";
    show_banner($fh);
    close $fh;

    unlike($out, qr/\x1b\[[0-9;]*m/, "No ANSI escapes emitted when colors are empty");
}
