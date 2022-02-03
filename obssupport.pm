#!/usr/bin/perl -w
package obssupport;
use strict;

require Exporter;
our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
$VERSION = "1.0";
@ISA = qw(Exporter);
@EXPORT = qw(
&addentry &diffhash &addsrinfo &addsrlinks
);

our %srinfo=();
our $debug=0;

sub addentry($$$)
{my($bugmap, $bugid,$sr)=@_;
	my $h=$bugmap->{$bugid}||{};
	my %h=%$h; # deep copy to allow diffhash to work
	$h{$sr}=1;
	$bugmap->{$bugid}=\%h;
}

sub addsrinfo($$)
{ my($sr,$extra)=@_;
	$srinfo{$sr}=$extra;
}

use SOAP::Transport::HTTP;  # Need for Basic Authorization subroutine
use XMLRPC::Lite;           # From the SOAP::Lite Module
use JSON::XS;
use config;

my $bugzillahandle;
sub bugzillahandle()
{
	$bugzillahandle=XMLRPC::Lite->proxy("https://${config::username}:$config::password\@apibugzilla.suse.com/xmlrpc.cgi") if(!$bugzillahandle);
	return $bugzillahandle;
}

sub SOAP::Transport::HTTP::Client::get_basic_credentials 
{ 
	return $config::username => $config::password;
}

sub die_on_fault 
{ my $soapresult = shift;
	if ($soapresult->fault)
	{
		die $soapresult->faultcode . ' ' . $soapresult->faultstring;
	}
}

sub getsummary($)
{ my($bugid)=@_;
	my $proxy=bugzillahandle();
	my $soapresult;
	my $result;
	eval {
		$soapresult = $proxy->call('Bug.get', {ids=>[$bugid]});
		$result = $soapresult->{_content}->[4]->{params}->[0]->{bugs}->[0]->{summary};
	};
	return $result;
}
sub getbug($)
{ my($bugid)=@_;
	my $proxy=bugzillahandle();
	my $soapresult;
	eval {$soapresult = $proxy->call('Bug.comments', {ids=>[$bugid]});};
	$soapresult ||= {_content=>[0,1,2,3,"failed $@"]};
}
sub bugjson($)
{ my $soapresult=shift;
	my $coder = JSON::XS->new->ascii->pretty->allow_nonref->allow_blessed->convert_blessed;
	my $bugjson=$coder->encode ($soapresult->{_content}->[4]);
}

sub filtersr($@)
{ my($bugjson, @sr)=@_;
	my @sr2=();
	return @sr2 if($bugjson=~m/\Afailed /);
	# drop linked SRs:
	foreach my $sr (@sr) {
		next if $bugjson=~m/request\/show\/$sr\b/;
		push(@sr2, $sr); # keep sr
	}
	return @sr2;
}

sub srurlplusinfo(@)
{
	return join("",map {
		my $sr=$_;
		my $info="";
		if(my $i=$srinfo{$sr}) {$info=" $i"}
		common::srurl($sr.$info)."\n";
	 } @_);
}

sub addbugcomment($$;$)
{ my($bugid, $comment, $p)=@_;
	my $proxy=bugzillahandle;
	$p||=0;
	my $soapresult2 = $proxy->call('Bug.add_comment', {id => $bugid, comment => $comment, is_private=>$p, private=>$p, isprivate=>$p});
	die_on_fault($soapresult2);
}

sub addsrlinks($@)
{ my($bugid, @sr)=@_;
	return 2 unless $bugid=~s/^bnc#//; # ignore others for now
	return 2 if $bugid < 1040000; # ignore bugs older than 5y
	eval { # catch die
		my @sr2=@sr;
		if(!$debug) { @sr2=filtersr(bugjson(getbug($bugid)), @sr);}
		return unless @sr2;
		my $comment="This is an autogenerated message for $config::bsname integration:\nThis bug ($bugid) was mentioned in\n".srurlplusinfo(@sr2)."\n";
		if(!$debug) {
			my $summary=getsummary($bugid);
			if(!$summary) {
				print "error - https://bugzilla.suse.com/show_bug.cgi?id=$bugid does not have a summary - does it even exist?\nSkipping...\n";
				return 1;
			}
			print "adding to https://bugzilla.suse.com/show_bug.cgi?id=$bugid\n> $summary\n$comment\n";
			addbugcomment($bugid, $comment, $config::privatecomment);
		} else {
			print "debug: would have added:\n$comment\n";
		}
	};
	return 1 unless $@; # all OK
	warn $@; # error
	return 0;
}

1;
