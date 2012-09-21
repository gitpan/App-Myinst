#!perl

use strict;
use warnings;
use Data::Dumper;
use Test::More qw/no_plan/;

BEGIN {
    use_ok( 'App::Myinst' ) || print "Bail out!\n";
}

diag( "Testing App::Myinst $App::Myinst::VERSION, Perl $], $^X" );