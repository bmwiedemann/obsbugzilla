package jira;
use strict;
use Net::Netrc;
use LWP::UserAgent;
use JSON::XS;
use lib ".";
use config;
use obssupport;

my $debug=0;
my $jiracreds = Net::Netrc->lookup('jira.suse.com');
die "need jira creds in ~/.netrc" unless $jiracreds;
my $ua = LWP::UserAgent->new;

sub getbug($)
{ my $issueid=shift;
    my $req = HTTP::Request->new(GET => "https://jira.suse.com/rest/api/2/issue/$issueid/comment");
    $req->authorization_basic($jiracreds->login(), $jiracreds->password());
    my $data = $ua->request($req)->as_string;
    # equivalent to
    #my $data = `curl -s -n "https://jira.suse.com/rest/api/2/issue/$issueid/comment"`;
    return $data;
}

sub getissue($$)
{ my $issueid=shift;
  my $srinfo=shift;
    my $req = HTTP::Request->new(GET => "https://jira.suse.com/rest/api/2/issue/$issueid");
    $req->authorization_basic($jiracreds->login(), $jiracreds->password());
    my $response = $ua->request($req);
    die "jira $issueid error" unless ($response->is_success);
    my $data=decode_json($response->decoded_content);
    my $issuetype = $data->{fields}->{issuetype}->{name};
    my $status = $data->{fields}->{status}->{name};
    if($issueid =~ m/^(PED)-/ and $srinfo =~ /SLE-15-SP6/ and ( $status =~ /Ready|Evaluation/i or $issuetype !~ /Implementation|Task/i)) { # TODO rework into updating jira ticket | notifying user
        system("echo 'jira warning: https://jira.suse.com/browse/$issueid status=$status issuetype=$issuetype\n$srinfo' | mailx -s IBS/obsbugzilla/jira rtsvetkov\@suse.com");
    }
    return $data;
}

sub addcomment($$)
{ my ($issueid, $comment) = @_;
    my $req = HTTP::Request->new(POST => "https://jira.suse.com/rest/api/2/issue/$issueid/comment");
    $req->authorization_basic($jiracreds->login(), $jiracreds->password());
    $req->header("Content-Type", "application/json");
    $req->content(encode_json({body=>$comment}));
    my $data = $ua->request($req);
    return 1;
}

sub filtersr($@)
{ my($bugjson, @sr)=@_;
	my @sr2=();
	return @sr2 if($bugjson=~m/\A\[\]/);
	# drop SRs that were already linked:
	foreach my $sr (@sr) {
		next if $bugjson=~m/request\/show\/$sr\b/;
		push(@sr2, $sr); # keep sr
	}
	return @sr2;
}

sub addjirasrlinks($@)
{ my($bugid, @sr)=@_;
        return 2 unless $bugid=~s/^js[cd]#//; # ignore others
        my @sr2=@sr;
        if(!$debug) { @sr2=filtersr(getbug($bugid), @sr);}
        return 1 unless @sr2;
        getissue($bugid, obssupport::srurlplusinfo(@sr2));
	my $comment="This is an autogenerated message for $config::bsname integration:\nThis bug ($bugid) was mentioned in\n".obssupport::srurlplusinfo(@sr2)."\n";
        print "submit $bugid, @sr2 $comment\n";
        if(!$debug) {
                addcomment($bugid, $comment);
        }
        return 1;
}

1;
