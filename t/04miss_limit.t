use Test::More tests=>4;

BEGIN { use_ok qw(File::LockDir) }

my $obj;
$obj = new File::LockDir({MissLimit=>20});

is $obj->miss_limit, 20, "right debug value";

my $obj2 = new File::LockDir;
is $obj, $obj2, "singleton works";
is $obj->miss_limit, 20, "still right debug value";

