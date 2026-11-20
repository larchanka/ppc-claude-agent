# --- Interactive model selection UI ---
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

    cursor_show();

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
    cursor_hide();
    return $selected_id;
}
