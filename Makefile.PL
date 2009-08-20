use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'File::LockDir',
    AUTHOR              => 'Joe McMahon <mcmahon@yahoo-inc.com>',
    VERSION_FROM        => 'lib/File/LockDir.pm',
    ABSTRACT_FROM       => 'lib/File/LockDir.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Carp'       => 0,
        'Cwd'        => 0,
        'Fcntl'         => 0,
        'Sys::Hostname' => 0,
        'File::Basename'=> 0,
        'File::Spec'    => 0,
        'Class::Accessor::Fast' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'File-LockDir-*' },
);
