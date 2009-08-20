use Test::More tests=>9;

BEGIN { use_ok qw(File::LockDir) }

my $obj;
$obj = new File::LockDir;
isa_ok $obj, "File::LockDir";
isa_ok $obj, "Class::Accessor::Fast";

is $obj->debug, 0, "right debug default";
is $obj->miss_limit, 10, "right miss limit default";
is $obj->check_sleep, 1, "right checkl_sleep default";
is ref $obj->_note, "CODE", "_note is a coderef";
is ref $obj->_fatal, "CODE", "_fatal is a coderef";

my $obj2 = new File::LockDir;

is $obj, $obj2, "singleton works";

