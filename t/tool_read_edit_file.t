#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Basename qw(dirname);
use File::Temp qw(tempdir);
use Cwd qw(abs_path);

my $root_dir = abs_path(dirname(__FILE__) . '/..');
$ENV{CLAUDE_CURL} = "$root_dir/t/mock_curl.pl";
$ENV{CLAUDE_CACERT} = "$root_dir/cacert.pem";
$ENV{MOCK_CURL_LOG} = "$root_dir/t/test_mock_curl.log";
delete $ENV{CLAUDE_AUTO_MODE};

require "$root_dir/claude-agent.pl";
our @TOOLS;

my $temp_dir = tempdir(CLEANUP => 1);

# ==================================================================
# Task 1: Extend read_file schema and line range slicing
# ==================================================================

# 1. Schema inspection
my ($read_file_tool) = grep { $_->{name} eq 'read_file' } @TOOLS;
ok($read_file_tool, "read_file tool exists in \@TOOLS");
is_deeply($read_file_tool->{input_schema}{required}, ['path'], "read_file required schema contains only path");

my $props = $read_file_tool->{input_schema}{properties};
ok($props->{path}, "path property exists");
is($props->{path}{type}, 'string', "path property is string");

ok($props->{start_line}, "start_line property exists in schema");
is($props->{start_line}{type}, 'integer', "start_line is integer");

ok($props->{end_line}, "end_line property exists in schema");
is($props->{end_line}{type}, 'integer', "end_line is integer");

# 2. File creation helper
sub write_temp_file {
    my ($filename, $content) = @_;
    my $path = "$temp_dir/$filename";
    open my $fh, '>:encoding(UTF-8)', $path or die "Cannot create temp file: $!";
    print $fh $content;
    close $fh;
    return $path;
}

my $test_file_content = "Line 1\nLine 2\nLine 3\nLine 4\nLine 5\n";
my $test_file = write_temp_file("test_read.txt", $test_file_content);

# 3. Full file read when start_line and end_line are omitted
is(
    run_tool('read_file', { path => $test_file }),
    $test_file_content,
    "Full file read when neither start_line nor end_line is specified"
);

# 4. Partial range reading [2, 4]
is(
    run_tool('read_file', { path => $test_file, start_line => 2, end_line => 4 }),
    "Line 2\nLine 3\nLine 4\n",
    "Line range [2, 4] reads lines 2 through 4"
);

# 5. Single line reading [3, 3]
is(
    run_tool('read_file', { path => $test_file, start_line => 3, end_line => 3 }),
    "Line 3\n",
    "Single line range [3, 3] reads line 3"
);

# 6. Only start_line specified (reads to EOF)
is(
    run_tool('read_file', { path => $test_file, start_line => 3 }),
    "Line 3\nLine 4\nLine 5\n",
    "Only start_line => 3 reads from line 3 to EOF"
);

# 7. Only end_line specified (reads from line 1)
is(
    run_tool('read_file', { path => $test_file, end_line => 2 }),
    "Line 1\nLine 2\n",
    "Only end_line => 2 reads from line 1 to line 2"
);

# 8. Bounds clamping: start_line < 1 clamped to 1
is(
    run_tool('read_file', { path => $test_file, start_line => 0, end_line => 2 }),
    "Line 1\nLine 2\n",
    "start_line => 0 clamped to 1"
);
is(
    run_tool('read_file', { path => $test_file, start_line => -5, end_line => 2 }),
    "Line 1\nLine 2\n",
    "start_line => -5 clamped to 1"
);

# 9. Bounds clamping: end_line > total clamped to total
is(
    run_tool('read_file', { path => $test_file, start_line => 4, end_line => 100 }),
    "Line 4\nLine 5\n",
    "end_line => 100 clamped to total (5)"
);

# 10. Out-of-bounds: start_line > total returns empty string
is(
    run_tool('read_file', { path => $test_file, start_line => 10, end_line => 20 }),
    "",
    "start_line => 10 > total returns empty string"
);
is(
    run_tool('read_file', { path => $test_file, start_line => 6 }),
    "",
    "start_line => 6 > total (omitted end_line) returns empty string"
);

# 11. Error validation: start_line > end_line
my $err_range = run_tool('read_file', { path => $test_file, start_line => 4, end_line => 2 });
is(
    $err_range,
    "Error: start_line (4) cannot be greater than end_line (2)",
    "Error returned when start_line > end_line"
);

# 12. Non-existent file returns error
my $err_no_file = run_tool('read_file', { path => "$temp_dir/does_not_exist.txt" });
like(
    $err_no_file,
    qr/^Error: cannot open /,
    "Non-existent file returns cannot open error"
);

# 13. Preserves lines without trailing newline at EOF
my $no_eof_nl = "First\nSecond\nThird";
my $no_eof_file = write_temp_file("no_eof.txt", $no_eof_nl);
is(
    run_tool('read_file', { path => $no_eof_file, start_line => 2, end_line => 3 }),
    "Second\nThird",
    "Range read preserves file ending without trailing newline"
);

# 14. UTF-8 multi-byte support
my $utf8_content = "こんにちは\n世界\nTiger 10.4\nPowerPC\n";
my $utf8_file = write_temp_file("utf8.txt", $utf8_content);
is(
    run_tool('read_file', { path => $utf8_file, start_line => 1, end_line => 2 }),
    "こんにちは\n世界\n",
    "Range read on UTF-8 content preserves multibyte characters"
);

done_testing();
