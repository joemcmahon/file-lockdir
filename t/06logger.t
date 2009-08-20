use Test::More tests=>4;

BEGIN { use_ok qw(File::LockDir) }

my $obj;
$obj = new File::LockDir({Logger=>\&dummy});

is $obj->_note, \&dummy, "right note value";

my $obj2 = new File::LockDir;
is $obj, $obj2, "singleton works";
is $obj->_note, \&dummy, "still right note value";

sub dummy { }
