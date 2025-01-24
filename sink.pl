#!/usr/bin/perl -w
use strict;

# zypper in perl-SOAP-Lite perl-LWP-Protocol-https perl-XMLRPC-Lite perl-MLDBM perl-JSON-XS
# usage: ./sink.pl
# uses entries from queue/ to post updates

use MLDBM qw(DB_File Storable);
use Fcntl qw(:DEFAULT :flock);
use lib "/usr/libexec/obsbugzilla";
use lib ".";
use config;
use common;
use obssupport;
open(my $fh, '>>', ".lockfile") or die $!;
flock($fh, LOCK_EX) or die $!;
my %data;
my $dbname="data/issuemention.dbm";
tie(%data, "MLDBM", $dbname, O_RDWR|O_CREAT, 0666) or die "error opening DB: $!";
my %bugmap1=%data;
my %bugmap2=%bugmap1;
untie(%data);

sub diag(@) #{print @_,"\n"}
{}

my @sinks = glob("sink/*.pm");
my $mentions = common::getcumulatedqueue();
foreach my $mention (keys %$mentions) {
    my $e1 = $mentions->{$mention};
    foreach my $id (keys %$e1) {
        my $e = $e1->{$id};
        my ($sr, $extra) = ($id, $e->{extra});
        diag("$sr ($extra) mention: $mention");
        addentry(\%bugmap2, $mention, $sr);
        addsrinfo($sr, $extra);
    }
}

# check which entries were new
foreach our $bugid (sort(keys(%bugmap2))) {
	our $diff=common::diffhash($bugmap2{$bugid}, $bugmap1{$bugid});
	if($diff && @$diff) {
		for my $sink (@sinks) {
			my $ret = do $sink; # uses $bugid and $diff
			if($ret) {
				print "OK\n";
			} else {
				print "failed\n";
				$bugmap2{$bugid} = $bugmap1{$bugid}; # avoid adding it as done
			}
		}
	}
}

tie(%data, "MLDBM", $dbname, O_RDWR|O_CREAT, 0666) or die "error opening DB: $!";
%data=%bugmap2;

untie(%data);
close($fh) or die $!;
