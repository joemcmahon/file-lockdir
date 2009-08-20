use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'File::LockDir',
    license             => 'perl',
    dist_author         => 'Joe McMahon <mcmahon@yahoo-inc.com>',
    dist_version_from   => 'lib/File/LockDir.pm',
    requires => {
        'Test::More' => 0,
        'Carp'       => 0,
        'Cwd'        => 0,
        'Fcntl'         => 0,
        'Sys::Hostname' => 0,
        'File::Basename'=> 0,
        'File::Spec'    => 0,
        'Class::Accessor::Fast' => 0,
    },
    add_to_cleanup      => [ 'File-LockDir-*' ],
);

$builder->create_build_script();
