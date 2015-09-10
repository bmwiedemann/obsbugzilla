#!/usr/bin/perl -w
use strict;
use config;

my @updates;
foreach my $source (@$config::sources) {
    require "source/$source.pm";
    my $result = eval "source::${source}::fetch()";
    if(!$result || ref($result) ne "ARRAY") {
        die "error $@ $result";
    }
    push(@updates, @$result);
}

#TODO maybe merge entries here

foreach my $sink (@$config::sinks) {
    require "sink/$sink.pm";
    my $result = eval "sink::${sink}::addentry(@updates)";
    if($result) {
        die "error $result";
    }
}

