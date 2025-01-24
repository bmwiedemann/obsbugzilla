#!/usr/bin/perl -w
use strict;
# usage: ./sourcerabbit.pl
# fetches rabbitmq events and stores entries in queue dir
use JSON::XS;
use lib "/usr/libexec/obsbugzilla";
use lib ".";
use config;
use common;
use source::OBS;

sub diag(@) #{print @_,"\n"}
{}

my $r=source::OBS::fetch();
foreach my $m (keys %$r) {
    my $data=$r->{$m};
    foreach my $m (keys(%$data)) {
        diag("adding $m ".encode_json($data->{$m}));
        common::enqueue($data->{$m});
    }
}
