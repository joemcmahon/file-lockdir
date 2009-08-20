use Test::More tests=>4;
use File::Spec;
use Cwd;

BEGIN { use_ok qw(File::LockDir) }

my $obj;
$obj = new File::LockDir;

is $obj->_name2lock("/etc/zorch"), "/etc/zorch.LOCKDIR", "works";
is $obj->_name2lock("./"), File::Spec->catfile(getcwd(),".LOCKDIR"), "works";
is $obj->_name2lock("alpha"), File::Spec->catfile(getcwd(),"alpha.LOCKDIR"), "works";
