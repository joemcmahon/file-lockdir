use Test::More tests=>3;

BEGIN { use_ok qw(File::LockDir) }

my $obj;
$obj = new File::LockDir({Fatal=>'wrong'});

isnt $obj->_fatal, 'wrong', "bad fatal value not accepted";
is ref $obj->_fatal, 'CODE', "default set up";
