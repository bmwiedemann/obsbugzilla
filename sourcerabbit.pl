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
use source::gitea;

sub diag(@) {print @_,"\n"}
#{}

$|=1;
$SIG{ALRM} = sub {source::rabbitmq::close(); exit 0};
source::rabbitmq::init();
while(my $data=source::rabbitmq::fetchone()) {
    alarm(24*3600);
    my $srmentions;
    if($data->{routing_key} =~ /\.src\..*pull_request/) {
        $srmentions=source::gitea::getprmentions($data);
    } else {
        $srmentions=source::OBS::getsrmentions($data);
    }
    foreach my $m (@$srmentions) {
        diag("adding $data->{number} ".encode_json($m));
	common::enqueue($m);
    }
}
