use Test::More tests => 4;
use lib '.';
use extractchanges;

my $s1 = "t/sample1.changes";
my $s3 = "t/sample3.changes";
is(extract_changes($s1, 123456), "Fix foo", "basic");
is(extract_changes($s3, 100001), "Fix bar as well", "basic2");
is(extract_changes($s3, 100002), "Also baz with a linebreak", "linebreak1");
is(extract_changes($s3, 100003), "And frorp That has a whole section with three lines", "linebreak2");

