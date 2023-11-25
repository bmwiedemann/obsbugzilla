package source::rabbitmq;
use threads;
use Thread::Queue;
use JSON::XS;
our $q = Thread::Queue->new();

sub fetchone()
{
    my $line = <RABBITPIPE>;
    return undef unless defined $line;
    my $data = decode_json($line);
    # map to search result structure:
    foreach my $a (@{$data->{actions}}) {
	if($a->{sourcepackage}) { $a->{source}->{package} = $a->{sourcepackage} }
	if($a->{sourceproject}) { $a->{source}->{project} = $a->{sourceproject} }
	if($a->{targetpackage}) { $a->{target}->{package} = $a->{targetpackage} }
	if($a->{targetproject}) { $a->{target}->{project} = $a->{targetproject} }
	if($a->{target_releaseproject}) { $a->{target}->{releaseproject} = $a->{target_releaseproject} }
    }
    $data->{action} = $data->{actions};
    return $data;
}

sub init()
{
    my $sourceprog="./opensuserabbit.py $config::rabbiturl $config::rabbitroutingprefix";
    if($ENV{RABBITTEST}) {$sourceprog="cat"}
    open(RABBITPIPE, "$sourceprog|") or die $!;
}

sub close()
{
    close(RABBITPIPE);
    system("killall opensuserabbit.py");
}
