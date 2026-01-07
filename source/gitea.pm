package source::gitea;
use strict;
use common;

our $jiraprojectre = join("|", common::getjiraprojects());

sub getprmentions($)
{
    my $data=shift;
    my $descr=$data->{title}.$data->{body};
    my $sr = $data->{url};
    $sr =~ s!https://[^/]+/!!; $sr=~s!/!:!g; $sr=~s/:pulls:/:/;
    my $package;
    $sr =~ m/([^:]+):\d+$/ and $package=$1;
    my $targetdistri = $data->{base}{ref};
    my @jiramentionids=($descr=~m/\b(js[cd]#(?:$jiraprojectre)-\d+)/go);
    my @mentionids=@jiramentionids;
    push(@mentionids, ($descr=~m/\b(\w+#\d{3,})/g));
    push(@mentionids, ($descr=~m/\b(CVE-20[1-4]\d-\d{4,})\b/g));
    my @mentions;
    foreach my $mention (@mentionids) {
        $mention=~s,https?://bugzilla\.opensuse\.org/show_bug\.cgi\?id=,boo#,;
        $mention=~s,https?://bugzilla\.suse.com/show_bug\.cgi\?id=,bsc#,;
        $mention=~s/boo#(\d{6,7}\b)/bnc#$1/; #bugzilla.opensuse.org
        $mention=~s/bsc#(\d{6,7}\b)/bnc#$1/; #bugzilla.suse.com
        $mention=~s/bug#(\d{6,7}\b)/bnc#$1/; # TODO: needs update when bug numbers go higher
        push(@mentions, {id=>$sr, url=>$data->{url}, distri=>$targetdistri, extra=>"$targetdistri / $package", mention=>$mention});#, time=>$when});
    }
    return \@mentions;
}

1;
