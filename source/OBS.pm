package source::OBS;
use Time::Local;
use config;
use XML::Simple;
use common;

sub parseisotime($)
{
    my $in=shift;
    return unless $in;
    return unless $in=~/^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})$/;
    my ($year, $month, $day, $h, $m, $s) = ($1,$2,$3,$4,$5,$6);
    $month--;
    return timegm($s, $m, $h, $day, $month, $year);
}

sub get_requests($)
{
    my $ns=shift;
    my @a=gmtime(time-1*24*60*60); $a[4]++; $a[5]+=1900;
    my $since=sprintf("%04i-%02i-%02i",$a[5],$a[4],$a[3]);
    open(my $f, "-|", qq!osc -A https://$config::apiserver api "/search/request?match=starts-with(action/target/\@project,'$ns')+and+(state/\@name='new'+or+state/\@name='review'+or+state/\@name='accepted')+and+state/\@when>='$since'"!) or die $!;
    local $/;
    my $xml=<$f>;
    if(length($xml)>30000000) { die "reply too long(".length($xml).") - not sane - stopping here"}
    close $f;
	 open($f, ">", "$ENV{HOME}/.osc.debug.xml"); print $f $xml; close $f;
    return $xml;
}

sub getsrmentions($)
{
    my $data=shift;
    my $sr=$data->{number};
    my @mentions=();
        # reduce spamminess by skipping requests that are no more interesting
        return [] if !$data->{state} || $data->{state} =~ m/deleted|revoked|superseded/;
        my ($type, $targetdistri, $package);
        foreach my $a (@{$data->{action}}) {
            next unless $a->{target};
            next unless $a->{type} =~ m/submit|maintenance_incident/;
            my $p=$a->{target}->{releaseproject} || $a->{target}->{project};
            next unless $p && $p=~m/^$config::namespace(.*)/;
            my $targetdistri1=$1;
            $targetdistri1=~s/:(Update|Test|GA)\b//;
            $targetdistri1=~s/Leap://;
            $p=$a->{target}->{package} || $a->{source}->{package};
            next unless $p;
            next if $p eq "patchinfo";
            $p=~s/_NonFree_Update//;
            $p=~s/\.openSUSE_Backports_SLE-\d\d(-SP\d)?//;
            $p=~s/\.openSUSE_(?:Leap_|Evergreen_)?\d\d\.\d(_Update)?//;
            $p=~s/\.SUSE_SLE-\d\d(-SP\d)?_Update//;
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
        $package=join("+", sort keys %$package);
        foreach my $mention ($descr=~m/\b(\w+#\d{3,})/g) {
            $mention=~s/boo#(\d{6,7}\b)/bnc#$1/; #bugzilla.opensuse.org
            $mention=~s/bsc#(\d{6,7}\b)/bnc#$1/; #bugzilla.suse.com
            $mention=~s/bug#(\d{6,7}\b)/bnc#$1/; # TODO: needs update when bug numbers go higher
            #print "$sr ($targetdistri / $package) mention: $mention\n";
            push(@mentions, {id=>$sr, url=>common::srurl($sr), distri=>$targetdistri, extra=>"$targetdistri / $package", mention=>$mention, time=>$when});
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
        $data->{state} = $data->{state}{name}; # make similar to rabbitmq
        $data->{when} = $data->{state}{when};
        $data->{number} = $sr;
        my $srmentions=getsrmentions($data);
        foreach my $m (@$srmentions) {
            common::addmapentry($results, $m);
        }
    }
    return $results;
}

1;
