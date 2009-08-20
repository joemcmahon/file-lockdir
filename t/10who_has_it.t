use Test::More tests=>2;

BEGIN { use_ok qw(File::LockDir) }

my $obj;
$obj = new File::LockDir({Fatal=>'wrong'});

is $obj->_who_has_it("/etc"), "/etc/owner", "works";
