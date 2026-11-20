#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use File::Temp qw(tempdir);

my $root_dir = abs_path(dirname(__FILE__) . '/..');
$ENV{CLAUDE_CURL} = "$root_dir/t/mock_curl.pl";
$ENV{CLAUDE_CACERT} = "$root_dir/cacert.pem";

system($^X, "$root_dir/build.pl") unless -f "$root_dir/code-agent.pl";
require "$root_dir/code-agent.pl";

# Test 1: get_env_file_path when both files are absent
{
    my $tmp = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $tmp;

    my $path = get_env_file_path();
    is($path, "$tmp/.code-agent-env", "get_env_file_path defaults to .code-agent-env when neither exists");
}

# Test 2: get_env_file_path fallback when only legacy .claude-agent-env exists
{
    my $tmp = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $tmp;
    my $legacy = "$tmp/.claude-agent-env";
    open(my $fh, '>', $legacy) or die "Cannot create $legacy: $!";
    print $fh "export TEST_KEY=123\n";
    close $fh;

    my $path = get_env_file_path();
    is($path, "$tmp/.claude-agent-env", "get_env_file_path falls back to .claude-agent-env when only legacy exists");
}

# Test 3: get_env_file_path preference when both files exist
{
    my $tmp = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $tmp;
    my $legacy = "$tmp/.claude-agent-env";
    my $new    = "$tmp/.code-agent-env";
    open(my $fh1, '>', $legacy) or die "Cannot create $legacy: $!";
    print $fh1 "export LEGACY=1\n";
    close $fh1;
    open(my $fh2, '>', $new) or die "Cannot create $new: $!";
    print $fh2 "export NEW=1\n";
    close $fh2;

    my $path = get_env_file_path();
    is($path, "$tmp/.code-agent-env", "get_env_file_path prefers .code-agent-env when both exist");
}

# Test 4: load_env_file loads variables without overwriting existing
{
    my $tmp = tempdir(CLEANUP => 1);
    my $env_file = "$tmp/.code-agent-env";
    open(my $fh, '>', $env_file) or die "Cannot create $env_file: $!";
    print $fh "export VAR_UNQUOTED=hello\n";
    print $fh "export VAR_DOUBLE_QUOTED=\"world\"\n";
    print $fh "export VAR_SINGLE_QUOTED='tiger'\n";
    print $fh "VAR_NO_EXPORT=plain\n";
    print $fh "export VAR_PREEXISTING=new_val\n";
    print $fh "# comment line\n";
    print $fh "\n";
    close $fh;

    local $ENV{VAR_PREEXISTING} = "original_val";
    delete $ENV{VAR_UNQUOTED};
    delete $ENV{VAR_DOUBLE_QUOTED};
    delete $ENV{VAR_SINGLE_QUOTED};
    delete $ENV{VAR_NO_EXPORT};

    load_env_file($env_file);

    is($ENV{VAR_UNQUOTED}, 'hello', "Unquoted env var loaded");
    is($ENV{VAR_DOUBLE_QUOTED}, 'world', "Double quoted env var loaded");
    is($ENV{VAR_SINGLE_QUOTED}, 'tiger', "Single quoted env var loaded");
    is($ENV{VAR_NO_EXPORT}, 'plain', "Var without export loaded");
    is($ENV{VAR_PREEXISTING}, 'original_val', "Existing env var not overwritten");
}

# Test 5: load_env_file falls back to legacy file when called with no arguments
{
    my $tmp = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $tmp;
    my $legacy = "$tmp/.claude-agent-env";
    open(my $fh, '>', $legacy) or die "Cannot create $legacy: $!";
    print $fh "export LEGACY_LOADED=yes\n";
    close $fh;

    delete $ENV{LEGACY_LOADED};
    load_env_file();

    is($ENV{LEGACY_LOADED}, 'yes', "load_env_file() loads from legacy file if .code-agent-env missing");
}

# Test 6: _maybe_save_gemini_key saves to .code-agent-env by default
{
    my $tmp = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $tmp;

    no warnings 'redefine';
    local *read_line_interactive = sub { return "y\n"; };
    use warnings 'redefine';

    _maybe_save_gemini_key("test_key_gemini_123");

    my $target = "$tmp/.code-agent-env";
    ok(-f $target, "_maybe_save_gemini_key creates .code-agent-env when clean install");
    open(my $fh, '<', $target) or die "Cannot read $target: $!";
    my $content = do { local $/; <$fh> };
    close $fh;
    like($content, qr/export GEMINI_API_KEY=test_key_gemini_123/, "Saved key is present in .code-agent-env");
}

# Test 7: _maybe_save_gemini_key updates legacy file if only legacy exists
{
    my $tmp = tempdir(CLEANUP => 1);
    local $ENV{HOME} = $tmp;
    my $legacy = "$tmp/.claude-agent-env";
    open(my $fh, '>', $legacy) or die "Cannot create $legacy: $!";
    print $fh "export OTHER_VAR=xyz\n";
    close $fh;

    no warnings 'redefine';
    local *read_line_interactive = sub { return "y\n"; };
    use warnings 'redefine';

    _maybe_save_gemini_key("legacy_target_key");

    ok(!-f "$tmp/.code-agent-env", ".code-agent-env not created when legacy file exists");
    open(my $rf, '<', $legacy) or die "Cannot read $legacy: $!";
    my $content = do { local $/; <$rf> };
    close $rf;
    like($content, qr/export OTHER_VAR=xyz/, "Preserved existing variables in legacy file");
    like($content, qr/export GEMINI_API_KEY=legacy_target_key/, "Appended new key to legacy file");
}

# Test 8: Shell wrapper compatibility logic (Install.command template)
{
    my $tmp = tempdir(CLEANUP => 1);
    my $wrapper = "$tmp/code";
    open(my $wh, '>', $wrapper) or die "Cannot create $wrapper: $!";
    print $wh <<"EOF";
#!/bin/bash
if [ -f "\$HOME/.code-agent-env" ]; then
  source "\$HOME/.code-agent-env"
elif [ -f "\$HOME/.claude-agent-env" ]; then
  source "\$HOME/.claude-agent-env"
fi
echo "PROVIDER=\$TEST_PROVIDER"
EOF
    close $wh;
    chmod 0755, $wrapper;

    # Scenario A: Modern .code-agent-env present
    my $home_modern = tempdir(CLEANUP => 1);
    open(my $mh, '>', "$home_modern/.code-agent-env") or die $!;
    print $mh "export TEST_PROVIDER=modern_code\n";
    close $mh;
    my $out_modern = `HOME="$home_modern" /bin/bash "$wrapper"`;
    chomp $out_modern;
    is($out_modern, "PROVIDER=modern_code", "Wrapper script sources modern .code-agent-env");

    # Scenario B: Only legacy .claude-agent-env present
    my $home_legacy = tempdir(CLEANUP => 1);
    open(my $lh, '>', "$home_legacy/.claude-agent-env") or die $!;
    print $lh "export TEST_PROVIDER=legacy_claude\n";
    close $lh;
    my $out_legacy = `HOME="$home_legacy" /bin/bash "$wrapper"`;
    chomp $out_legacy;
    is($out_legacy, "PROVIDER=legacy_claude", "Wrapper script falls back to legacy .claude-agent-env");
}

done_testing();
