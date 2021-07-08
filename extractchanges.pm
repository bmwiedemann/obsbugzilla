
sub extract_changes($$)
{ my ($file, $bugid) = @_;
    open(my $fd, "<", $file) or die $!;
    local $/ = undef;
    my $lines = <$fd>;
    my $re = qr/\(?(boo|bsc|bnc)#$bugid\)?/;
    #print $lines;
    if($lines =~ m/(.*)$re/) {
        $_ = $1;
	s/^\s*[-+*] //;
	s/[ (]+$//;
	return $_;
    }
    return "";
}

1;
