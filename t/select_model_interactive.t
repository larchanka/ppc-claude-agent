#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Basename qw(dirname);
use Cwd qw(abs_path);

my $root_dir = abs_path(dirname(__FILE__) . '/..');
$ENV{CLAUDE_CURL} = "$root_dir/t/mock_curl.pl";
$ENV{CLAUDE_CACERT} = "$root_dir/cacert.pem";

require "$root_dir/code-agent.pl";

# Helper to create a pipe with given data written into it
sub make_input_pipe {
    my ($data) = @_;
    pipe(my $reader, my $writer) or die "Cannot create pipe: $!";
    if (defined $data && length($data) > 0) {
        syswrite($writer, $data);
    }
    close $writer;
    return $reader;
}

# Helper to create an open pipe pair where writer stays open (for Esc timeout tests)
sub make_open_pipe {
    my ($data) = @_;
    pipe(my $reader, my $writer) or die "Cannot create pipe: $!";
    if (defined $data && length($data) > 0) {
        syswrite($writer, $data);
    }
    return ($reader, $writer);
}

my $sample_models = [
    { id => 'claude-3-opus-20240229', display => 'Claude 3 Opus' },
    { id => 'claude-3-5-sonnet-20241022', display => 'Claude 3.5 Sonnet' },
    { id => 'claude-3-5-haiku-20241022', display => 'Claude 3.5 Haiku' },
];

# ==================================================================
# 1. Edge cases: empty / undef models
# ==================================================================
{
    is(select_model_interactive(undef), undef, "undef models returns undef");
    is(select_model_interactive([]), undef, "empty models arrayref returns undef");
    is(select_model_interactive("not an array"), undef, "non-arrayref returns undef");
}

# ==================================================================
# 2. Non-TTY / Non-interactive fallback
# ==================================================================
{
    local $main::FORCE_RAW = 0;

    # Test selecting by number
    {
        my $in = make_input_pipe("2\n");
        open my $out, '>', \my $captured;
        my $selected = select_model_interactive($sample_models, 'claude-3-opus-20240229', $in, $out);
        is($selected, 'claude-3-5-sonnet-20241022', "Non-tty: selected item 2 by index");
        like($captured, qr/Available models:/, "Non-tty: displayed available models header");
        like($captured, qr/\(current\)/, "Non-tty: marked current model");
    }

    # Test selecting by exact model ID
    {
        my $in = make_input_pipe("claude-3-5-haiku-20241022\n");
        open my $out, '>', \my $captured;
        my $selected = select_model_interactive($sample_models, undef, $in, $out);
        is($selected, 'claude-3-5-haiku-20241022', "Non-tty: selected by exact model ID string");
    }

    # Test empty input / cancel
    {
        my $in = make_input_pipe("\n");
        open my $out, '>', \my $captured;
        my $selected = select_model_interactive($sample_models, undef, $in, $out);
        is($selected, undef, "Non-tty: empty input returns undef (cancelled)");
    }

    # Test explicit 'q' / cancel
    {
        my $in = make_input_pipe("q\n");
        open my $out, '>', \my $captured;
        my $selected = select_model_interactive($sample_models, undef, $in, $out);
        is($selected, undef, "Non-tty: 'q' cancels and returns undef");
    }

    # Test 'exit' with whitespace / cancel
    {
        my $in = make_input_pipe("   exit   \n");
        open my $out, '>', \my $captured;
        my $selected = select_model_interactive($sample_models, undef, $in, $out);
        is($selected, undef, "Non-tty: 'exit' with spaces cancels and returns undef");
    }

    # Test out-of-range number
    {
        my $in = make_input_pipe("99\n");
        open my $out, '>', \my $captured;
        my $selected = select_model_interactive($sample_models, undef, $in, $out);
        is($selected, undef, "Non-tty: out of range index returns undef");
    }

    # Test EOF
    {
        my $in = make_input_pipe("");
        open my $out, '>', \my $captured;
        my $selected = select_model_interactive($sample_models, undef, $in, $out);
        is($selected, undef, "Non-tty: EOF returns undef");
    }

    # Test models as simple strings array
    {
        my $string_models = ['model-alpha', 'model-beta'];
        my $in = make_input_pipe("1\n");
        open my $out, '>', \my $captured;
        my $selected = select_model_interactive($string_models, undef, $in, $out);
        is($selected, 'model-alpha', "Non-tty: models passed as plain string arrayref");
    }
}

# ==================================================================
# 3. Interactive Raw Mode: Enter Confirmation & Initial Cursor
# ==================================================================
{
    local $main::FORCE_RAW = 1;

    # Immediate Enter confirms default (first) model
    {
        my $in = make_input_pipe("\r");
        open my $out, '>', \my $captured;
        my $selected = select_model_interactive($sample_models, undef, $in, $out);
        is($selected, 'claude-3-opus-20240229', "Raw mode: immediate Enter confirms first item");
    }

    # Immediate Enter confirms current model when matched
    {
        my $in = make_input_pipe("\n");
        open my $out, '>', \my $captured;
        my $selected = select_model_interactive($sample_models, 'claude-3-5-sonnet-20241022', $in, $out);
        is($selected, 'claude-3-5-sonnet-20241022', "Raw mode: Enter confirms pre-selected current model");
    }
}

# ==================================================================
# 4. Interactive Raw Mode: Arrow Key Navigation
# ==================================================================
{
    local $main::FORCE_RAW = 1;

    # Down arrow then Enter
    {
        # \x1b[B is Down arrow
        my $in = make_input_pipe("\x1b[B\r");
        open my $out, '>', \my $captured;
        my $selected = select_model_interactive($sample_models, undef, $in, $out);
        is($selected, 'claude-3-5-sonnet-20241022', "Raw mode: Down arrow navigates to second item");
    }

    # Down arrow twice then Enter
    {
        my $in = make_input_pipe("\x1b[B\x1b[B\r");
        open my $out, '>', \my $captured;
        my $selected = select_model_interactive($sample_models, undef, $in, $out);
        is($selected, 'claude-3-5-haiku-20241022', "Raw mode: Down arrow twice navigates to third item");
    }

    # Down arrow past end clamps to last item
    {
        my $in = make_input_pipe("\x1b[B\x1b[B\x1b[B\x1b[B\r");
        open my $out, '>', \my $captured;
        my $selected = select_model_interactive($sample_models, undef, $in, $out);
        is($selected, 'claude-3-5-haiku-20241022', "Raw mode: Down arrow at bottom clamps to last item");
    }

    # Up arrow from second item back to first
    {
        my $in = make_input_pipe("\x1b[A\r");
        open my $out, '>', \my $captured;
        my $selected = select_model_interactive($sample_models, 'claude-3-5-sonnet-20241022', $in, $out);
        is($selected, 'claude-3-opus-20240229', "Raw mode: Up arrow navigates back up");
    }

    # Up arrow at top clamps to first item
    {
        my $in = make_input_pipe("\x1b[A\x1b[A\r");
        open my $out, '>', \my $captured;
        my $selected = select_model_interactive($sample_models, 'claude-3-opus-20240229', $in, $out);
        is($selected, 'claude-3-opus-20240229', "Raw mode: Up arrow at top clamps to first item");
    }

    # Right arrow navigates down / Left arrow navigates up
    {
        my $in = make_input_pipe("\x1b[C\r");
        open my $out, '>', \my $captured;
        my $selected = select_model_interactive($sample_models, 'claude-3-opus-20240229', $in, $out);
        is($selected, 'claude-3-5-sonnet-20241022', "Raw mode: Right arrow navigates to next item");
    }
    {
        my $in = make_input_pipe("\x1b[D\r");
        open my $out, '>', \my $captured;
        my $selected = select_model_interactive($sample_models, 'claude-3-5-sonnet-20241022', $in, $out);
        is($selected, 'claude-3-opus-20240229', "Raw mode: Left arrow navigates to previous item");
    }
}

# ==================================================================
# 5. Interactive Raw Mode: Esc Cancellation & Ctrl-C
# ==================================================================
{
    local $main::FORCE_RAW = 1;

    # Standalone Esc (0x1b) with timeout
    {
        my ($r, $w) = make_open_pipe("\x1b");
        open my $out, '>', \my $captured;
        my $selected = select_model_interactive($sample_models, undef, $r, $out);
        is($selected, undef, "Raw mode: Standalone Esc cancels and returns undef");
        close $w;
    }

    # Handle without fileno (e.g. in-memory scalar ref) returns undef without warnings
    {
        my $esc_data = "\x1b";
        open my $mem_in, '<', \$esc_data;
        open my $out, '>', \my $captured;
        my $warnings = '';
        local $SIG{__WARN__} = sub { $warnings .= $_[0] };
        my $selected = select_model_interactive($sample_models, undef, $mem_in, $out);
        is($selected, undef, "Raw mode: in-memory handle without fileno cancels cleanly");
        is($warnings, '', "Raw mode: no uninitialized warnings on handle without fileno");
    }

    # Ctrl-C (0x03)
    {
        my $in = make_input_pipe("\x03");
        open my $out, '>', \my $captured;
        my $selected = select_model_interactive($sample_models, undef, $in, $out);
        is($selected, undef, "Raw mode: Ctrl-C cancels and returns undef");
    }

    # EOF during raw mode
    {
        my $in = make_input_pipe("");
        open my $out, '>', \my $captured;
        my $selected = select_model_interactive($sample_models, undef, $in, $out);
        is($selected, undef, "Raw mode: EOF returns undef");
    }
}

# ==================================================================
# 6. Interactive Raw Mode: Numeric Selection & Typing
# ==================================================================
{
    local $main::FORCE_RAW = 1;

    # Typing '3' then Enter
    {
        my $in = make_input_pipe("3\r");
        open my $out, '>', \my $captured;
        my $selected = select_model_interactive($sample_models, undef, $in, $out);
        is($selected, 'claude-3-5-haiku-20241022', "Raw mode: typing '3' jumps to item 3");
    }

    # Multi-digit typing with larger model list
    {
        my @many_models = map { { id => "model-$_", display => "Model $_" } } (1 .. 25);
        my $in = make_input_pipe("18\r");
        open my $out, '>', \my $captured;
        my $selected = select_model_interactive(\@many_models, undef, $in, $out);
        is($selected, 'model-18', "Raw mode: multi-digit typing '18' jumps to item 18");
    }

    # Typing with Backspace
    {
        # Type '1', '9', Backspace (0x7f), '8', Enter
        my $in = make_input_pipe("19\x7f8\r");
        open my $out, '>', \my $captured;
        my @many_models = map { { id => "model-$_", display => "Model $_" } } (1 .. 25);
        my $selected = select_model_interactive(\@many_models, undef, $in, $out);
        is($selected, 'model-18', "Raw mode: Backspace corrects typed digits");
    }

    # Typing a number larger than list length rolls over to the single typed digit
    {
        my $in = make_input_pipe("92\r");
        open my $out, '>', \my $captured;
        my $selected = select_model_interactive($sample_models, undef, $in, $out);
        is($selected, 'claude-3-5-sonnet-20241022', "Raw mode: out-of-bounds digit rolls over to digit '2'");
    }

    # Very long model label truncation test
    {
        my $long_id = 'model-' . ('x' x 80);
        my $in = make_input_pipe("\r");
        open my $out, '>', \my $captured;
        my $selected = select_model_interactive([{ id => $long_id, display => $long_id }], undef, $in, $out);
        is($selected, $long_id, "Raw mode: returns full long id");
        like($captured, qr/\.\.\./, "Raw mode: truncated display label with ellipsis");
    }
}

# ==================================================================
# 7. Interactive Raw Mode: Pagination / Windowing (> 15 models)
# ==================================================================
{
    local $main::FORCE_RAW = 1;

    my @many_models = map { { id => "m-$_", display => "Test Model $_" } } (1 .. 30);

    # Verify window bounds & navigation on large list
    {
        # Navigate down 15 times
        my $keys = ("\x1b[B" x 15) . "\r";
        my $in = make_input_pipe($keys);
        open my $out, '>', \my $captured;
        my $selected = select_model_interactive(\@many_models, undef, $in, $out);
        is($selected, 'm-16', "Raw mode: Window scrolls correctly on 30 items down to item 16");
        like($captured, qr/showing/i, "Raw mode: Pagination info displayed in output");
    }

    # Pre-selected item far down the list initializes window appropriately
    {
        my $in = make_input_pipe("\r");
        open my $out, '>', \my $captured;
        my $selected = select_model_interactive(\@many_models, 'm-25', $in, $out);
        is($selected, 'm-25', "Raw mode: Current model at index 24 correctly pre-selected and confirmed");
    }
}

done_testing();
