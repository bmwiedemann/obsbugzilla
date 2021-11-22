package common;
use JSON::XS;
use open qw( :std :encoding(UTF-8) );

our $minage=30*60;

sub srurl($;$$)
{
	my ($sr, $url, $info) = @_;
	if (!$url) { $url = "https://$config::buildserver/request/show/$sr" }
	$info ||= "";
	return $url.$info;
}

sub get_file_content($) {my($fn)=@_;;

   open(FCONTENT, "<", $fn) or return undef;
   local $/;
   my $result=<FCONTENT>;
   close(FCONTENT);
   return $result;
}
sub set_file_content($$) {my($fn,$data)=@_;
   open(my $fc, ">", $fn) or return undef;
   print $fc $data;
   close($fc);
}

sub addmapentry($$)
{my($bugmap, $data)=@_;
	my $id=$data->{id};
	my $mention=$data->{mention};
	my $h=$bugmap->{$mention}||{};
	my %h=%$h; # deep copy to allow diffhash to work
	$h{$id}=$data;
	$bugmap->{$mention}=\%h;
}

my $jsoncoder = JSON::XS->new->pretty->canonical;

sub enqueue($)
{my($mention)=shift;
	my $mentionid=$mention->{mention};
	my $srcid=$mention->{id};
	mkdir "queue";
	mkdir "queue/$mentionid";
	set_file_content("queue/$mentionid/$srcid", $jsoncoder->encode($mention));
}

sub getcumulatedqueue()
{
	my %result;
	for my $mentiondir (<queue/*>) {
		my $mtime = (stat($mentiondir))[9];
		next if not defined $mtime or $mtime > time - $minage;
		for my $srfile (<$mentiondir/*>) {
			my $json = get_file_content($srfile) or die "$srfile: $!";
			my $data = $jsoncoder->decode($json) or die "invalid JSON in $srfile";
			$result{$data->{mention}}->{$data->{id}} = $data;
		}
	}
	return \%result;
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

sub getjiraprojects()
{
    my $file = "data/jiraproject.json";
    my $data = decode_json(get_file_content($file) or die "$file: $!");
    return map {$_->{key}} (@$data);
}

1;
