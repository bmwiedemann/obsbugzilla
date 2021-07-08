
sub extract_changes($$)
{ my ($file, $bugid) = @_;
    open(my $fd, "<", $file) or die $!;
    local $/ = undef;
    my $lines = <$fd>;
    my $re = qr/\(?(boo|bsc|bnc)#$bugid\)?/;
    #print $lines;
    if($lines =~ m/\n\s*[+*-] ((?:[^+*-]|(?<!\s).(?! )){1,300}?)$re/s) {
        $_ = $1;
	s/^\s*[+*-] //;
	s/[\n ]+/ /g;
	s/[\n (]+$//;
	return $_;
    }
    return "";
}

1;
