use Test::More tests=>4;

BEGIN { use_ok qw(File::LockDir) }

my $obj;
$obj = new File::LockDir({Interval=>1});

is $obj->check_sleep, 1, "right debug value";

my $obj2 = new File::LockDir;
is $obj, $obj2, "singleton works";
is $obj->check_sleep, 1, "still right debug value";

