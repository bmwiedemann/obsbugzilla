
sub extract_changes($$)
{ my ($file, $bugid) = @_;
    open(my $fd, "<", $file) or die $!;
    local $/ = undef;
    my $lines = <$fd>;
    my $re = qr/\(?(boo|bsc|bnc)\s?#$bugid\)?/;
    #print $lines;
    if($lines =~ m/\n\s*[+*-] ((?:[^+*-]|(?<!\s).(?! )){1,300}$re[^\n]*)/s) {
        $_ = $1;
	s/$re[. ]*$//;
	s/^\s*[+*-] //;
	s/[\n ]+/ /g;
	s/[\n (]+$//;
	return $_;
    }
    return "";
}

1;
