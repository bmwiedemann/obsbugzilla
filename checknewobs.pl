#!/usr/bin/perl -w
use strict;

# zypper in perl-SOAP-Lite perl-LWP-Protocol-https
# usage: ./checknewobs.pl

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

sub get_requests($)
{
	my $ns=shift;
	my @a=gmtime(time-24*60*60); $a[4]++; $a[5]+=1900; 
	my $since=sprintf("%04i-%02i-%02i",$a[5],$a[4],$a[3]);
	open(my $f, "-|", qq!osc api "/search/request?match=starts-with(action/target/\@project,'$ns')+and+(state/\@name='new'+or+state/\@name='review'+or+state/\@name='accepted')+and+state/\@when>='$since'"!) or die $!;
	#open(my $f, "-|", qq!osc api "/search/request?match=starts-with(action/target/\@project,'$ns')+and+(state/\@name='new'+or+state/\@name='review')+and+state/\@when>='$since'"!) or die $!;
	#open(my $f, "<", "request.new.xml") or die $!;
	local $/;
	my $xml=<$f>;
	close $f;
	return $xml;
}

my $requests=get_requests($obssupport::namespace);
#die length($requests);
if(!$requests || $requests!~m{<collection matches=}) {
	system('echo "'.$obssupport::hermesurl.' failed" | mailx -s OBS -c bwiedemann@suse.de');
	print "opensuse site failed\n" ; exit 17
} # opensuse site failed
my $reqdata=XMLin($requests, ForceArray=>['action','history'], keyattr=>['id']);
$requests=$reqdata->{request};
use JSON::XS; my $coder = JSON::XS->new->ascii->pretty->allow_nonref->allow_blessed->convert_blessed;
#print $coder->encode($reqdata);
foreach my $sr (sort keys %$requests) {
	my $data=$requests->{$sr};
	my ($type,$targetdistri, $package);
   # reduce spamminess by skipping requests that are no more interesting
	next if $data->{state}{name} =~ m/deleted|revoked|superseded/; 
	foreach my $a (@{$data->{action}}) {
		next unless $a->{target};
		next unless $a->{type} =~ m/submit|maintenance_incident/;
		my $p=$a->{target}->{releaseproject} || $a->{target}->{project};
		next unless $p && $p=~m/^$obssupport::namespace(.*)/;
		my $targetdistri1=$1;
		$targetdistri1=~s/:Update$//;
		$p=$a->{target}->{package} || $a->{source}->{package};
		next unless $p;
		next if $p eq "patchinfo";
		$p=~s/\.openSUSE_1\d\.\d_Update//;
		$targetdistri->{$targetdistri1}=1;
		$package->{$p}=1;
		$type=$a->{type};
		#print "$sr: $type @$targetdistri / $package\n";
	}
	next unless $type;
	my $descr=$data->{description}||"";
	my $lt=qr/(?:<|&lt;)/;
	my $gt=qr/(?:>|&gt;)/;
	if($type eq "delete") {
		if($descr=~m/openSUSE:Factory/) {
			#print "SR:$sr $type $descr";
		}
		next;
	}
	$targetdistri=join("+", keys %$targetdistri);
	$package=join("+", keys %$package);
	foreach my $mention ($descr=~m/\b(\w+#\d{3,})/g) {
		$mention=~s/boo#([8-9]\d{5}\b)/bnc#$1/; #bugzilla.opensuse.org
		$mention=~s/bsc#([8-9]\d{5}\b)/bnc#$1/; #bugzilla.suse.com
		$mention=~s/bug#([6-9]\d{5}\b)/bnc#$1/; # TODO: needs update when bug numbers go higher
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
		print "obs ./bugzillaaddsr.pl $bugid @$diff\n";
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
