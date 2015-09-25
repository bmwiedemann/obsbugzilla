package common;

sub addmapentry($$$$)
{my($bugmap, $mention, $id, $data)=@_;
	my $h=$bugmap->{$mention}||{};
	my %h=%$h; # deep copy to allow diffhash to work
	$h{$id}=$data;
	$bugmap->{$mention}=\%h;
}

# returns an arrayref of keys that are in h1, but not h2
# h1 is assumed to always contain more entries than h2
sub diffhash($$)
{ my($h1,$h2)=@_;
	my @a=();
	foreach my $x (sort(keys(%$h1))) {
		next if($h2->{$x});
		push(@a,$x)
	}
	return \@a;
}

1;
