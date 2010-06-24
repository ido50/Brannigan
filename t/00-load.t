#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Brannigan' ) || print "Bail out!
";
}

diag( "Testing Brannigan $Brannigan::VERSION, Perl $], $^X" );
