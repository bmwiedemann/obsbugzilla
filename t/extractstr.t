use Test::More tests => 1;
use lib '.';
use extractchanges;

is(extract_changes_from_str("- Fix foo (boo#123456)", 123456), "Fix foo", "basic");
