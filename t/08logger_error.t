use Test::More tests=>3;

BEGIN { use_ok qw(File::LockDir) }

my $obj;
$obj = new File::LockDir({Logger=>7});

isnt $obj->_note, 7, "bad value not accepted";
is ref $obj->_note, "CODE", "default coderef";
