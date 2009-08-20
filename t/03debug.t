use Test::More tests=>4;

BEGIN { use_ok qw(File::LockDir) }

my $obj;
$obj = new File::LockDir({Debug=>1});

is $obj->debug, 1, "right debug value";

my $obj2 = new File::LockDir;
is $obj, $obj2, "singleton works";
is $obj->debug, 1, "still right debug value";

