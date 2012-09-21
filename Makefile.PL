use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::Myinst',
    AUTHOR              => q{Satoshi Yagi <satoshi.yagi@yahoo.com>},
    VERSION_FROM        => 'lib/App/Myinst.pm',
    ABSTRACT_FROM       => 'lib/App/Myinst.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'            => 0,
        'Parallel::ForkManager' => 0,
        'Log::Log4perl'         => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-Myinst-*' },
);
