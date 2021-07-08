use Test::More tests => 16;
use lib '.';
use extractchanges;

my $s1 = "t/sample1.changes";
my $s3 = "t/sample3.changes";
my $s4 = "t/sample4.changes";
is(extract_changes($s1, 123456), "Fix foo", "basic");
is(extract_changes($s3, 100001), "Fix bar as well", "basic2");
is(extract_changes($s3, 100002), "Also baz with a linebreak", "linebreak1");
is(extract_changes($s3, 100003), "And frorp That has a whole section with three lines", "linebreak2");
is(extract_changes($s3, 100004), "And carp", "trailing1");
is(extract_changes($s3, 100004), "And carp", "trailing1");
is(extract_changes($s3, 100005), "with subentries for issues", "sub1");
is(extract_changes($s3, 100006), "with subentries for issues", "sub2");
is(extract_changes($s3, 100007), "with subentries for issues", "sub3");
is(extract_changes($s3, 100008), "with subentries with multiple lines for one issue", "submulti1");

# advanced level
is(extract_changes($s4, 1046571), "Fix missing global for 32-bit version with gcc7.", "advanced1");
is(extract_changes($s4, 1037291), "Fix several problems with the startup scripts. The SysV form is no longer used for most packages as proper systemd service files have been created. These fixes address bsc#1037291, #1043532, and #1045871.", "advanced2");
is(extract_changes($s4, 1014694), 'Revert "vbox_hdpi_support.patch. This patch may improve things for asn@cryptomilk.org, but it breaks other systems. See https://forums.opensuse.org/showthread.php/521520-VirtualBox-interface-scaling and', "advanced3");
is(extract_changes($s4, 1183329), 'Fixes boo#1183329 "virtualbox 6.1.18 crashes when it runs nested VM"', "advanced4");
is(extract_changes($s4, 896776), 'Add upstream patches bash43-027 which fixed bsc#898604 bash43-026 which fixes CVE-2014-7169 and bsc#898346 bash43-025 which replaces bash-4.3-CVE-2014-6271.patch and fixes', "advanced5");
is(extract_changes($s4, 959755), 'Make clear that the files /etc/profile as well as /etc/bash.bashrc may source other files as well even if the bash does not. Therefore modify patch bash-4.1-bash.bashrc.dif', "bash2");
