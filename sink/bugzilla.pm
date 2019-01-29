use lib ".";
use obssupport;

print "$config::bsname ./bugzillaaddsr.pl $bugid @$diff\n";
addsrlinks($bugid, @$diff);
