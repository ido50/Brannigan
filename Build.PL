use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Brannigan',
    license             => 'perl',
    dist_author         => q{Ido Perlmuter <ido@ido50.net>},
    dist_version_from   => 'lib/Brannigan.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Brannigan-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
