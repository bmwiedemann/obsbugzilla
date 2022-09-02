package source::OBS;
use strict;
use Time::Local;
use config;
use XML::Simple;
use common;
use lib '.';
use extractchanges::extractchanges;

our $jiraprojectre = join("|", common::getjiraprojects());

sub parseisotime($)
{
    my $in=shift;
    return unless $in;
    return unless $in=~/^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})$/;
    my ($year, $month, $day, $h, $m, $s) = ($1,$2,$3,$4,$5,$6);
    $month--;
    return timegm($s, $m, $h, $day, $month, $year);
}

sub api_pipe(@)
{
    my $pid = open(my $pipefd, "-|");
    defined($pid)          || die "can't fork: $!";

    if ($pid) {            # parent
        return $pipefd
    } else {               # child
        exec("osc", "-A", "https://$config::apiserver", "api", @_)
                           || die "can't exec program: $!";
                           # NOTREACHED
    }
}

sub get_requests($)
{
    my $ns=shift;
    my @a=gmtime(time-1*24*60*60); $a[4]++; $a[5]+=1900;
    my $since=sprintf("%04i-%02i-%02i",$a[5],$a[4],$a[3]);
    my $f = api_pipe(qq!/search/request?match=starts-with(action/target/\@project,'$ns')+and+(state/\@name='new'+or+state/\@name='review'+or+state/\@name='accepted')+and+state/\@when>='$since'!);
    local $/;
    my $xml=<$f>;
    if(length($xml)>70000000) { die "reply too long(".length($xml).") - not sane - stopping here"}
    close $f;
	 open($f, ">", "$ENV{HOME}/.osc.debug.xml"); print $f $xml; close $f;
    return $xml;
}

# returns a list of mentions: ["boo#123456", "jsc#SLE-12345"]
sub getsrdiffmentions($)
{
    my $sr=shift;
    my $xml=`osc -A https://$config::apiserver api -X POST "/request/$sr?cmd=diff&withissues=1&view=xml"`;
    $xml//=""; chomp($xml);
    if(length($xml)>30000000) { warn "SR $sr reply too long(".length($xml).") - not sane - skipping..."; return () }
    if($? != 0) {
        warn "problem with SR $sr: $xml";
        return ();
    }
    my $extradata=XMLin($xml, ForceArray=>['action','issue','sourcediff'], keyattr=>['id']);
    my @mentions=();
    foreach my $a (@{$extradata->{action}}) {
        my $sourcediff=$a->{sourcediff};
        foreach my $s (@$sourcediff) {
            my $issues = $s->{issues}->{issue};
            foreach my $i (@$issues) {
                next unless $i->{tracker} =~ m/bnc|jsc/;
                next if $i->{state} ne "added";
                push(@mentions, "$i->{tracker}#$i->{name}");
            }
        }
    }
    return @mentions;
}

# add extra info from changes files
sub enrichsrmention($)
{
    my $m = shift; # mention hashref
    my $bugnumber = $m->{mention};
    $bugnumber =~ s/bnc#//;
    my $changestext = "FIXME";
    extract_changes_from_str($changestext, $bugnumber);

}

sub getsrmentions($)
{
    my $data=shift;
    my $sr=$data->{number};
    my @mentions=();
        # reduce spamminess by skipping requests that are no more interesting
        if(!$data->{state} || $data->{state} =~ m/deleted|revoked|superseded|declined/) {
            for(<queue/*/$sr>) {unlink $_}
            return [];
        }
        my ($type, $targetdistri, $package, $is_mr);
        foreach my $a (@{$data->{action}}) {
            next unless $a->{target};
            next unless $a->{type} =~ m/submit|maintenance_incident/;
            $is_mr = 1 if $a->{type} eq "maintenance_incident";
            my $p=$a->{target}->{releaseproject} || $a->{target}->{project};
            next unless $p && $p=~m/^$config::namespace(.*)/;
            my $targetdistri1=$1;
            $targetdistri1=~s/:(Update|Products|Test|GA)\b//g;
            $targetdistri1=~s/Leap://;
	    next if $targetdistri1 eq "SLE-15-SP2:MicroOS" and time() < 1640991600; # temp during devel
	    next if $targetdistri1 =~ m/SaltBundleBeta/ and time() < 1672527600; # temp during devel requested by Dirk
	    next if $targetdistri1 eq "SLE-15-SP6" and time() < 1701385200; # temp during devel
            next if $targetdistri1 eq "SLE-15-SP5" and time() < 1669849200; # temp during devel
            $p=$a->{target}->{package} || $a->{source}->{package};
            next unless $p;
            next if $p =~ /^patchinfo/;
            my $sourceproject=$a->{source}->{project}||"";
            next if $sourceproject eq 'openSUSE:Factory';
            $p=~s/_Update$//;
            $p=~s/_NonFree$//;
            $p=~s/-SP\d$//;
            $p=~s/\.openSUSE_Backports_SLE-\d\d//;
            $p=~s/\.openSUSE_(?:Leap_|Evergreen_)?\d\d\.\d//;
            $p=~s/\.SUSE_SLE-\d\d//;
            $targetdistri->{$targetdistri1}=1;
            $package->{$p}=1;
            $type=$a->{type};
            #print "$sr: $type @$targetdistri / $package\n";
        }
        return [] unless $type;
        my $descr=$data->{description}||"";
        if($type eq "delete") {
            if($descr=~m/openSUSE:Factory/) {
                #print "SR:$sr $type $descr";
            }
            return [];
        }
        my $when = parseisotime($data->{when}) || time();
        $targetdistri=join("+", sort keys %$targetdistri);
        if(scalar(keys %$package) > 50) {
            $package="[".(scalar(keys %$package))." packages]";
        } else {
            $package=join("+", sort keys %$package);
        }
        my @jiramentionids=($descr=~m/\b(js[cd]#(?:$jiraprojectre)-\d+)/go);
        my @mentionids=@jiramentionids;
        push(@mentionids, ($descr=~m/\b(\w+#\d{3,})/g));
        foreach my $mention (@mentionids) {
            $mention=~s/boo#(\d{6,7}\b)/bnc#$1/; #bugzilla.opensuse.org
            $mention=~s/bsc#(\d{6,7}\b)/bnc#$1/; #bugzilla.suse.com
            $mention=~s/bug#(\d{6,7}\b)/bnc#$1/; # TODO: needs update when bug numbers go higher
            #print "$sr ($targetdistri / $package) mention: $mention\n";
            push(@mentions, {id=>$sr, url=>common::srurl($sr), distri=>$targetdistri, extra=>"$targetdistri / $package", mention=>$mention, time=>$when});
        }
        if($is_mr) {
            my @m = getsrdiffmentions($sr);
            foreach my $m (@m) {
                $m = {id=>$sr, url=>common::srurl($sr), distri=>$targetdistri, extra=>"$targetdistri / $package", mention=>$m, time=>$when, data=>$data};
                enrichsrmention($m);
                push(@mentions, $m);
            }
        }
    return \@mentions;
}

sub fetch()
{
    my $requests=get_requests($config::namespace);
    if(!$requests || $requests!~m{<collection matches=}) {
        system('echo "OBS SR source failed" | mailx -s OBS bwiedemann@suse.de');
        print "OBS api failed\n" ; exit 17
    }
    my $reqdata=XMLin($requests, ForceArray=>['request','action','history'], keyattr=>['id']);
    $requests=$reqdata->{request};
    my $results={};
    foreach my $sr (sort keys %$requests) {
        my $data=$requests->{$sr};
        next if !$data->{state};
        $data->{when} = $data->{state}{when};
        $data->{state} = $data->{state}{name}; # make similar to rabbitmq
        $data->{number} = $sr;
        my $srmentions=getsrmentions($data);
        foreach my $m (@$srmentions) {
            common::addmapentry($results, $m);
        }
    }
    return $results;
}

1;
