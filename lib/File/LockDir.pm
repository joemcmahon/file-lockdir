package File::LockDir;

our $VERSION = '0.02';

use warnings;
use strict;
use Carp;

use Cwd;
use Fcntl;
use Sys::Hostname;
use File::Basename;
use File::Spec;

use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw(_fatal _note debug check_sleep miss_limit cleanup));

my $singleton;

sub new {
    my ($class,$hashref) = @_;
    if (!defined $singleton) {
      my $self = {};
      bless $self, $class;

      $self->{LockedFiles} = {};

      if (exists $hashref->{Cleanup}) {
        $self->cleanup($hashref->{Cleanup});
      }
      else {
        $self->cleanup(0);
      }

      if (exists $hashref->{Debug}) {
        $self->debug($hashref->{Debug});
      }
      else {
        $self->debug(0);
      }

      if (exists $hashref->{MissLimit}) {
        $self->miss_limit($hashref->{MissLimit});
      }
      else {
        $self->miss_limit(10);
      }

      if (exists $hashref->{Interval}) {
        $self->check_sleep($hashref->{Interval});
      }
      else {
        $self->check_sleep(1);
      }

      if (exists $hashref->{Logger} and ref $hashref->{Logger} eq 'CODE') {
        $self->_note($hashref->{Logger});
      }
      else {
        $self->_note( sub{ print STDERR "@_" } );
      }

      if (exists $hashref->{Fatal} and ref $hashref->{Fatal} eq 'CODE') {
        $self->_fatal($hashref->{Fatal});
      }
      else {
        $self->_fatal( sub{ croak "@_" } );
      }
      $singleton = $self;
    }

    return $singleton;
}

sub _readlock {
  my ($self, $pathname) = @_;
  my $who_has_it = $self->_who_has_it($pathname);

  my $owner;
  if (!open($owner, "<", $who_has_it)) {
    if (!-e $who_has_it) {
      # Not locked, so there's nobody holding the lock.
      return (undef, 1, undef);
    }
    else {
      croak "Can't read lock file $who_has_it: $!\n";
    }
  }

  # Lock file exists and can be read.
  my $lockee = <$owner>;
  close $owner;

  chomp $lockee if defined $lockee;

  # Output debug message if required.
  my $note =
    "@{[scalar localtime]} $0\[$$]: lock on $pathname held by $lockee\n";

  $self->_note->($note) if $self->debug();

  # Locked, and this is who it is.
  return (undef, $lockee);
}

sub nflock {
    my($self, $pathname, $naptime, $locker, $lockhost) = @_;
    croak "No pathname to be locked" unless $pathname;

    $naptime  = (defined $naptime ) ? $naptime  : 0;
    $locker   = (defined $locker  ) ? $locker   : "anonymous";
    $lockhost = (defined $lockhost) ? $lockhost : hostname();

    my $lockname = $self->_name2lock($pathname);
    my $who_has_it = $self->_who_has_it($lockname);

    my $start    = time();
    my $missed   = 0;

    # if locking what I've already locked, return
    if (exists $self->{LockedFiles}->{$pathname}) {
        $self->_note->("$pathname already locked");
        return 1;
    }

    # Need to put the lock next to the file. Die if we can't.
    if (!-w dirname($pathname)) {
        fatal("can't write to directory of $pathname");
    }

    my $lockee;

    while (1) {
        last if mkdir($lockname, 0777);
        confess "Can't get $lockname: $!"
          if $missed++ > $self->miss_limit() && !-d $lockname;

        my($unlocked, $owner) = $self->_readlock($lockname);
        last if $unlocked;
        sleep $self->check_sleep();

        # If total time to wait has been exceeded, and the lock is
        # still held, return the current status of the lock.
        if ($naptime && time > $start+$naptime) {
          return (undef, $owner);
        }
    }
    sysopen(my $lockfile, $who_has_it, O_WRONLY|O_CREAT|O_EXCL)
      or fatal("can't create $who_has_it: $!");

    my $line = "$locker from $lockhost since @{[scalar localtime]}\n";
    print $lockfile $line;
    close($lockfile)
      or fatal("close failed for $who_has_it: $!");
    $self->{LockedFiles}->{$pathname} = $line;
    return (1, undef);
}

sub nunflock {
    my ($self, $pathname) = @_;

    my $lockname = $self->_name2lock($pathname);
    my $who_has_it = $self->_who_has_it($lockname);
    unlink($who_has_it);

    $self->_note->("releasing lock on $lockname") if $self->debug();
    delete $self->{LockedFiles}->{$pathname};

    return rmdir($lockname);
}

# check the state of the lock, bu don't try to get it
sub nlock_state {
    my($self, $pathname) = @_;

    my $lockname = $self->_name2lock($pathname);
    my $who_has_it = $self->_who_has_it($lockname);

    # Check lock cache first.
    return (undef, $self->{LockedFiles}->{$pathname})
      if $self->{LockedFiles}->{$pathname};

    # No directory - never locked.
    return (1, undef) if ! -d $lockname;

    # Could possibly be locked. Read the lockfile to check (if possible).
    return $self->_readlock($lockname);
}

sub _name2lock {
    my($self, $pathname) = @_;

    my $dir  = dirname($pathname);
    my $file = basename($pathname);

    $dir = getcwd() if $dir eq '.';
    $file = '' if $file eq '.';
    my $lockname = File::Spec->catfile($dir, "$file.LOCKDIR");
    return $lockname;
}

sub _who_has_it {
  my ($self, $pathname) = @_;
  return File::Spec->catfile($pathname, "owner");
}

END {
  if ($singleton && $singleton->cleanup) {
    for my $pathname (keys %{ $singleton->{LockFiles} }) {
      my $lockname = $singleton->_name2lock($pathname);
      my $who_has_it = $singleton->_who_has_it($lockname);
      carp "releasing forgotten $lockname";
      unlink $who_has_it;
      rmdir $lockname;
    }
  }
}

1; # Magic true value required at end of module
__END__

=head1 NAME

File::LockDir - basic filename-level lock utility

=head1 VERSION

This document describes File::LockDir version 0.02

=head1 SYNOPSIS

    use File::LockDir;


=head1 DESCRIPTION

=head1 INTERFACE

=head2 new

Initializes the class. Returns the singleton object.

=head2 nflock($file, $nap_till, $locker, $lockhost)

Locks the supplied filename. Only $file is required.

$file is the file to be locked; $nap_till is the total amount of time to
wait before giving up; $locker is a name identifying the locker;
$lockhost is the host requesting the lock.

=head2 nunflock($file)

Unlocks the supplied file.

=head2 nlock_state($file)

Checks the state of the lock for the supplied file. Returns a list:
the first item is true if the file is unlocked, and false if not;
the second item is undef if the file is unlocked, and the identity (name
and host) is it is locked.

=head1 DIAGNOSTICS

=over

=item C<< %s already locked >>

Seen when you've already locked the requested pathname. Informational only.

=item C<< No pathname to be locked >>

You didn't supply a pathname to be locked to nflock. Fatal.

=item C<< can't write to directory of %s >>

The directory where the file resides can't be written, so the lockfile
can't be created.

=item C<< can't get %s: %s >>

The named lock can't be gotten: the reason is supplied. Failure occurs
after ten tries to get the lock.

=item C<< %s %s[%s]: lock on %s held by %s >>

The lock on the specified file is help by the noted locker. Informatory
message, printed only when debugging is on.

=item C<< close failed for %s: %s >>

The file containing the lock information couldn't be closed for the
reason shown.

=item C<< releasing lock on %s >>

Debug message; notes that the lock on the specified file was
successfully released.

=back

=head1 CONFIGURATION AND ENVIRONMENT

File::LockDir requires no configuration files or environment variables.


=head1 DEPENDENCIES

None.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-file-lockdir@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Joe McMahon  C<< <mcmahon@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Joe McMahon C<< <mcmahon@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
