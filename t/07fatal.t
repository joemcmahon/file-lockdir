use Test::More tests=>4;

BEGIN { use_ok qw(File::LockDir) }

my $obj;
$obj = new File::LockDir({Fatal=>\&dummy});

is $obj->_fatal, \&dummy, "right fatal value";

my $obj2 = new File::LockDir;
is $obj, $obj2, "singleton works";
is $obj->_fatal, \&dummy, "still right fatal value";

sub dummy { }
