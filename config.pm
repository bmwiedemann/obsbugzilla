package config;

our ($username,$password);
our $apiserver="api.opensuse.org";
our $namespace="openSUSE:";
our $privatecomment=0;
eval(`/bin/cat $ENV{HOME}/.bugzillarc`);
our $buildserver=$config::apiserver; $buildserver=~s/api\./build./; # by convention

1;
