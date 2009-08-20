use Test::More tests => 11;

use strict;
use File::LockDir;
use Sys::Hostname;
my @LOG;

sub appender {
  push @LOG, "@_";
}

my $locker = File::LockDir->new({Debug=>1, Logger=>\&appender});

# Remove all locks
unlink("alpha.LOCKDIR/owner");
unlink("beta.LOCKDIR/owner");
rmdir("alpha.LOCKDIR");
rmdir("beta.LOCKDIR");

my($got_lock, $holder) = $locker->nflock("alpha", 1, $ENV{USER});
ok $got_lock, "Got lock on 'alpha'" or diag "$holder already has the lock";
is @LOG,0, "nothing logged";

(my $lockstate, $holder) = $locker->nlock_state("alpha");
ok !defined $lockstate, "alpha lock is held";
like $holder, qr/$ENV{USER} from @{[hostname()]} since/, "lock message right";

($lockstate, $holder) = $locker->nlock_state("beta");
ok defined $lockstate, "beta lock is NOT held";
ok !$holder, "message right";

my $unlocked = $locker->nunflock("alpha");
is $unlocked, 1, "unlock worked";

($lockstate, $holder) = $locker->nlock_state("alpha");
ok defined $lockstate, "alpha lock NOT held";
ok !$holder, "lock message right";

($lockstate, $holder) = $locker->nlock_state("beta");
ok defined $lockstate, "beta lock is NOT held";
ok !$holder, "message right";

# Clean up outstanding locks.
unlink(".LOCKDIR/owner");
rmdir(".LOCKDIR");
