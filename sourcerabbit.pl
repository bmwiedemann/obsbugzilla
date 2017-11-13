#!/usr/bin/perl -w
use strict;
# usage: ./sourcerabbit.pl
# fetches rabbitmq events and stores entries in queue dir
use JSON::XS;
use lib ".";
use config;
use common;
use source::rabbitmq;
use source::OBS;

sub diag(@) {print @_,"\n"}
#{}

source::rabbitmq::init();
while(my $data=source::rabbitmq::fetchone()) {
    my $srmentions=source::OBS::getsrmentions($data);
    foreach my $m (@$srmentions) {
        diag("adding $data->{number} ".encode_json($m));
	common::enqueue($m);
    }
}
