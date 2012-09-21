#!/usr/bin/perl

use strict;
use warnings;
use App::Myinst;
use Test::More qw/no_plan/;

print "Enter hostname #1: ";
chomp( my $host1 = <STDIN> );

print "Enter hostname #2: ";
chomp( my $host2 = <STDIN> );

print "Enter output directory: ";
chomp( my $dir = <STDIN> );

my $hosts = join( ",", $host1, $host2 );

# gasp -- this is an anonymous array, since some args are just flags
my $args = [
    'ssh',
    '--h'               => $hosts,
    '--f',
    '--dir'             => $dir,
    'ls -la | head',
    '-d',
];

unshift @ARGV, @{ $args };
App::Myinst->run();

my $log1 = "$dir/$host1.log";
my $log2 = "$dir/$host2.log";

# proper way is to use Test::File, but I don't want the test script requiring a non-core module
is( -f $log1, 1, "Test to see if $log1 exists" );
is( -f $log2, 1, "Test to see if $log2 exists" );