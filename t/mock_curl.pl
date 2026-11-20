#!/usr/bin/perl
use strict;
use warnings;

my $config_path;
for (my $i = 0; $i < @ARGV; $i++) {
    if ($ARGV[$i] eq '-K' && defined $ARGV[$i+1]) {
        $config_path = $ARGV[$i+1];
        last;
    }
}

die "No -K config provided\n" unless $config_path && -f $config_path;

open my $fh, '<', $config_path or die "Cannot read $config_path: $!";
my $config_content = do { local $/; <$fh> };
close $fh;

my $log_path = $ENV{MOCK_CURL_LOG} || '/tmp/mock_curl.log';
open my $lf, '>', $log_path or die "Cannot write $log_path: $!";
print $lf $config_content;
close $lf;

my ($output_path) = $config_content =~ /^output\s*=\s*"([^"]+)"/m;
my ($req_path)    = $config_content =~ /^data-binary\s*=\s*"\@([^"]+)"/m;

# Check if request tempfile exists in /tmp
my $req_status_path = $ENV{MOCK_CURL_REQ_CHECK} || '/tmp/mock_curl_req.log';
open my $rf, '>', $req_status_path or die "Cannot write $req_status_path: $!";
if ($req_path && -e $req_path) {
    print $rf "REQ_EXISTS:$req_path\n";
}
else {
    # Also check if any code-agent-req-$$.json or claude-agent-req-$$.json exists
    my ($parent_pid) = $config_path =~ /curlcfg-(\d+)\.txt/;
    if ($parent_pid && -e "/tmp/code-agent-req-$parent_pid.json") {
        print $rf "REQ_EXISTS:/tmp/code-agent-req-$parent_pid.json\n";
    }
    elsif ($parent_pid && -e "/tmp/claude-agent-req-$parent_pid.json") {
        print $rf "REQ_EXISTS:/tmp/claude-agent-req-$parent_pid.json\n";
    }
    else {
        print $rf "REQ_NONE\n";
    }
}
close $rf;

if ($output_path) {
    open my $of, '>', $output_path or die "Cannot write $output_path: $!";
    my $mock_resp = $ENV{MOCK_CURL_RESPONSE} || '{"status":"ok"}';
    print $of $mock_resp;
    close $of;
}

my $code = $ENV{MOCK_CURL_HTTP_CODE} || '200';
print $code;
exit 0;
