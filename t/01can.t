use Test::More tests=>4;

BEGIN { use_ok qw(File::LockDir) }

my $obj;
$obj = new File::LockDir;

isa_ok $obj, "File::LockDir";
can_ok $obj, qw(_fatal _note debug check_sleep miss_limit _readlock);
can_ok $obj, qw(nflock nunflock nlock_state _name2lock _who_has_it);
