use 5.010_001;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name              => 'Loctools::Markdown',
    license                  => 'MIT',
    dist_author              => 'Igor Afanasyev <igor.afanasyev@gmail.com>',
    dist_version_from        => 'lib/Loctools/Markdown.pm',
    release_status           => 'testing',
    configure_requires       => {
        'Module::Build'         => 0,
    },
    build_requires => {
        'File::Copy::Recursive' => 0,
        'Test::More'            => '0.94',
        'Text::Diff'            => 0,
    },
    requires => {
        'perl'                  => '5.10.0',
        'JSON'                  => 0,
    },
    add_to_cleanup           => ['Loctools-*', 'Makefile.PL', 'MYMETA.*', 'META.*', 'MANIFEST.bak', 'MANIFEST'],
    create_makefile_pl       => 'traditional',
);

$builder->create_build_script();
