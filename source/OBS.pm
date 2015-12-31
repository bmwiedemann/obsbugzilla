package source::OBS;
use config;
use XML::Simple;
use common;

sub get_requests($)
{
    my $ns=shift;
    my @a=gmtime(time-24*60*60); $a[4]++; $a[5]+=1900;
    my $since=sprintf("%04i-%02i-%02i",$a[5],$a[4],$a[3]);
    open(my $f, "-|", qq!osc -A https://$config::apiserver api "/search/request?match=starts-with(action/target/\@project,'$ns')+and+(state/\@name='new'+or+state/\@name='review'+or+state/\@name='accepted')+and+state/\@when>='$since'"!) or die $!;
    local $/;
    my $xml=<$f>;
    close $f;
    return $xml;
}

sub srurl(@)
{
    return join("",map {"https://$config::buildserver/request/show/$_\n"} @_);
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
        my ($type,$targetdistri, $package);
        # reduce spamminess by skipping requests that are no more interesting
        next if !$data->{state} || $data->{state}{name} =~ m/deleted|revoked|superseded/;
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
            $mention=~s/boo#(\d{6,7}\b)/bnc#$1/; #bugzilla.opensuse.org
            $mention=~s/bsc#(\d{6,7}\b)/bnc#$1/; #bugzilla.suse.com
            $mention=~s/bug#(\d{6,7}\b)/bnc#$1/; # TODO: needs update when bug numbers go higher
            #print "$sr ($targetdistri / $package) mention: $mention\n";
            common::addmapentry($results, $mention, $sr, {id=>$sr, url=>srurl($sr), distri=>$targetdistri, extra=>"$targetdistri / $package"});
        }
    }
    return $results;
}

1;
