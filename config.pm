package config;

our ($username,$password);
our $apiserver="api.opensuse.org";
our $namespace="openSUSE:";
our $privatecomment=0;
our $sources=["OBS"];
our $sinks=["bugzilla"];
eval(`/bin/cat $ENV{HOME}/.bugzillarc`);
if(!$username || !$password) {
    die "need username and password specified in .bugzillarc";
}
our $buildserver=$config::apiserver; $buildserver=~s/api\./build./; # by convention

1;
