sub extract_changes_from_str($$)
{ my ($lines, $bugid) = @_;
    my $re = qr/\(?(boo|bsc|bnc)\s?#$bugid\)?/;
    #print $lines;
    if($lines =~ m/ ((?:[^+*-]|(?<!\s).(?! )){1,300}$re[^\n]*)/s) {
        $_ = $1;
	s/$re[. ]*$//;
	s/^\s*[+*-] //;
	s/[\n ]+/ /g;
	s/[\n (]+$//;
	return $_;
    }
    return "";
}

sub extract_changes($$)
{ my ($file, $bugid) = @_;
    open(my $fd, "<", $file) or die $!;
    local $/ = undef;
    my $lines = <$fd>;
    return extract_changes_from_str($lines, $bugid);
}

1;
