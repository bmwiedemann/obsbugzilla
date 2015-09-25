package common;

sub addmapentry($$$$)
{my($bugmap, $mention, $id, $data)=@_;
	my $h=$bugmap->{$mention}||{};
	my %h=%$h; # deep copy to allow diffhash to work
	$h{$id}=$data;
	$bugmap->{$mention}=\%h;
}

1;
