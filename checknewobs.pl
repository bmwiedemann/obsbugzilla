#!/usr/bin/perl -w
use strict;

# zypper in perl-SOAP-Lite perl-LWP-Protocol-https
# usage: ./checknewobs.pl

use MLDBM qw(DB_File Storable);
use Fcntl;
use config;
use common;
use obssupport;
use source::OBS;
my %data;
my $dbname="issuemention.dbm";
tie(%data, "MLDBM", $dbname, O_RDWR|O_CREAT, 0666) or die "error opening DB: $!";
my %bugmap1=%data;
my %bugmap2=%bugmap1;

sub diag(@) #{print @_,"\n"}
{}

my $mentions = source::OBS::fetch();
foreach my $mention (keys %$mentions) {
    my $e1 = $mentions->{$mention};
    foreach my $id (keys %$e1) {
        my $e = $e1->{$id};
        my ($sr, $extra) = ($id, $e->{extra});
        #print "$sr ($extra) mention: $mention\n";
        addentry(\%bugmap2, $mention, $sr);
        addsrinfo($sr, $extra, $e);
    }
}

# check which entries were new
foreach my $bugid (sort(keys(%bugmap2))) {
	my $diff=common::diffhash($bugmap2{$bugid}, $bugmap1{$bugid});
	if($diff && @$diff) {
#		my $msg="> https://bugzilla.suse.com/show_bug.cgi?id=$bugid\nThis bug ($bugid) was mentioned in\n".
#		join("", map {"https://build.opensuse.org/request/show/$_\n"} @$diff)."\n";
#		print $msg;
		print "$config::bsname ./bugzillaaddsr.pl $bugid @$diff\n";
		if(addsrlinks($bugid, @$diff)) {
			print "OK\n";
		} else {
			print "failed\n";
			$bugmap2{$bugid} = $data{$bugid}; # avoid adding it as done
		}
#		system("./bugzillaaddsr.pl", $bugid, @$diff);
	}
}

%data=%bugmap2;

untie(%data);
#print "checknewobs.pl done\n"

#exec("withlock /dev/shm/updatecache.lock ./updatecache");
