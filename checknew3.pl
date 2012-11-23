#!/usr/bin/perl -w
use strict;

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


my $rdf=get("https://hermes.opensuse.org/feeds/77208.rdf");
if(!$rdf || $rdf!~m{<title>new submitreq</title>}) {
	system('echo "https://hermes.opensuse.org/feeds/77208.rdf failed" | mailx -s OBS/hermes -c bwiedemann@suse.de -c coolo@suse.de cwh@suse.de');
	print "opensuse site failed\n" ; exit 17
} # opensuse site failed
my $rdfdata=XMLin($rdf);
my $item=$rdfdata->{channel}->{item};
foreach my $i (@$item) {
	next unless $i->{title}=~m/^\[obs submit-request (\d+)\]/;
	my $sr=$1;
	my $descr=$i->{description};
   my $lt=qr/(?:<|&lt;)/;
   my $gt=qr/(?:>|&gt;)/;
	next unless $descr=~m!${lt}pre$gt\s+\S+ -$gt openSUSE:((?:Evergreen:)?[^:/]*)[^/]*/([^/ \n]*)!; # target
	diag $descr;
	my ($targetdistri, $package)=($1,$2);
   $descr=~s/change[sd] files:.*//s; # drop diff - mentions too many bnc
	foreach my $mention ($descr=~m/\b(\w+#\d{3,})/g) {
		$mention=~s/bug#([67]\d{5}\b)/bnc#$1/; # TODO: needs update when bug numbers go higher
#		print "$sr ($targetdistri / $package) mention: $mention\n";
		addentry(\%bugmap2, $mention, $sr);
		addsrinfo($sr, $targetdistri, $package);
	}
}

# check which entries were new
foreach my $bugid (sort(keys(%bugmap2))) {
	my $diff=diffhash($bugmap2{$bugid}, $bugmap1{$bugid});
	if($diff && @$diff) {
#		my $msg="> https://bugzilla.novell.com/show_bug.cgi?id=$bugid\nThis bug ($bugid) was mentioned in\n".
#		join("", map {"https://build.opensuse.org/request/show/$_\n"} @$diff)."\n";
#		print $msg;
		print "./bugzillaaddsr.pl $bugid @$diff\n";
		addsrlinks($bugid, @$diff) and print "OK\n";
#		system("./bugzillaaddsr.pl", $bugid, @$diff);
	}
}

%data=%bugmap2;

untie(%data);

#exec("withlock /dev/shm/updatecache.lock ./updatecache");
