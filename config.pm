package config;

our ($username,$password);
our ($fallbackusername,$fallbackpassword);
our $apiserver="api.opensuse.org";
our $namespace="openSUSE:";
our $bsname="OBS";
our $privatecomment=0;
our $rabbiturl='amqps://opensuse:opensuse@rabbit.opensuse.org';
our $rabbitroutingprefix='opensuse';
eval(`/bin/cat $ENV{HOME}/.bugzillarc`);
if(!$username || !$password) {
    die "need username and password specified in .bugzillarc";
}
our $buildserver=$config::apiserver; $buildserver=~s/api\./build./; # by convention

1;
