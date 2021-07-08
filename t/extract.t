use Test::More tests => 1;
use lib '.';
use extractchanges;

my $s1 = "t/sample1.changes";
is(extract_changes($s1, 123456), "Fix foo", "basic");

