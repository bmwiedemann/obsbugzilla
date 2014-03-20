#!/usr/bin/perl -w
use strict;

# zypper in perl-SOAP-Lite perl-LWP-Protocol-https
# https://mercurius.suse.de/feeds/264.rdf
# use https://hermes.opensuse.org/feeds/77208.rdf | 77212 - needs ~10 mins to update
# usage: ./checknew3.pl

use LWP::Simple;
use XML::Simple;
use MLDBM qw(DB_File Storable);
use Fcntl;
use obssupport;
my %data;
my $dbname="issuemention.dbm";
tie(%data, "MLDBM", $dbname, O_RDWR|O_CREAT, 0666) or die "error opening DB: $!";
my %bugmap1=%data;
my %bugmap2=%bugmap1;

sub diag(@) #{print @_,"\n"}
{}


my $rdf=get("https://mercurius.suse.de/feeds/264.rdf");
if(!$rdf || $rdf!~m{<title>new submitreq</title>}) {
	system('echo "https://mercurius.suse.de/feeds/264.rdf failed" | mailx -s IBS/mercurius bwiedemann@suse.de');
	print "IBS site failed\n" ; exit 17
} # opensuse site failed
$rdf=~s/[\001-\010\013-\014\016-\037]//g; # drop invalid control chars
my $rdfdata=XMLin($rdf);
my $item=$rdfdata->{channel}->{item};
foreach my $i (@$item) {
	my ($sr,$type);
	if($i->{title}=~m/^\[ibs (maintenance_incident|submit|delete)-request (\d+)\]/) {
		$sr=$2;
		$type=$1;
	}
	next unless $sr;
	my $descr=$i->{description};
   my $lt=qr/(?:<|&lt;)/;
   my $gt=qr/(?:>|&gt;)/;
	my ($targetdistri, $package);
	if($type eq "delete") {
		if($descr=~m/openSUSE:Factory/) {
			#print "SR:$sr $type $descr";
		}
		next;
	}
	if($type eq "maintenance_incident") {
		($targetdistri, $package)=("Maintenance","");
	} else {
		next unless $descr=~m!${lt}pre$gt\s+\S+ -$gt SUSE:([^:/]*[^/]*)/([^/ \n]*)!; # target
		diag $descr;
		($targetdistri, $package)=($1,$2);
		$targetdistri=~s/:(Update|Test|GA)\b//g;
	}
   $descr=~s/change[sd] files:.*//s; # drop diff - mentions too many bnc
	foreach my $mention ($descr=~m/\b(\w+#\d{3,})/g) {
		$mention=~s/bug#([6-9]\d{5}\b)/bnc#$1/; # TODO: needs update when bug numbers go higher
		$mention=~s/userbnc#/bnc#/; # https://build.suse.de/request/show/30168
		$mention=~s/BNC#/bnc#/;
		$mention=~s/boo#([8-9]\d{5}\b)/bnc#$1/; #bugzilla.opensuse.org
		$mention=~s/bsc#([8-9]\d{5}\b)/bnc#$1/; #bugzilla.suse.com
#		print "$sr ($targetdistri / $package) mention: $mention\n";
		addentry(\%bugmap2, $mention, $sr);
		addsrinfo($sr, $targetdistri, $package);
	}
}

# check which entries were new
foreach my $bugid (sort(keys(%bugmap2))) {
	my $diff=diffhash($bugmap2{$bugid}, $bugmap1{$bugid});
	if($diff && @$diff) {
#		my $msg="> https://bugzilla.suse.com/show_bug.cgi?id=$bugid\nThis bug ($bugid) was mentioned in\n".
#		join("", map {"https://build.opensuse.org/request/show/$_\n"} @$diff)."\n";
#		print $msg;
		print "./bugzillaaddsr.pl $bugid @$diff\n";
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

#exec("withlock /dev/shm/updatecache.lock ./updatecache");
