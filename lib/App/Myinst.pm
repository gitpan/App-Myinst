package App::Myinst;

use 5.006;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use Parallel::ForkManager;
use Log::Log4perl qw(:easy);
use Getopt::Long qw(:config no_ignore_case); # needed to support -h and -H

=head1 NAME

App::Myinst - Implements very limited features of a legendary command-line tool
at an iconic internet company.

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

The user of this module is expected to create a small driver script like this:

    $ vi myinst.pl
    #!/usr/bin/perl
    
    use strict;
    use warnings;
    use App::Myinst;

    App::Myinst->run();
    
and run with options.

Usage: ./myinst.pl <command> -h host1,host2 -j 4 "<remote_command>"
Implements very limited features of a legendary command-line tool at an iconic
internet company.

    <command>           command to myinst.  currently, only "ssh" is supported
    -h                  hostname, can be a comma-separated list with username like user@host
    -H                  specify a file with hostnames in it
    -j                  number of jobs to execute in parallel.  default: 1
    -f                  flag to save output in a file per host.  default: cwd
    -dir                if -f is specified, you may specify the output directory
    -d                  debug mode
    <remote_command>    the command to run on the remote hosts
    
Note on testing:
This module wraps around ssh and as such, requires authentication.
I have included an interactive test_deeply.pl script for those interested in
testing.

=head1 SUBROUTINES/METHODS

=head2 new

	Description: The constructor.  Creates object then calls init().
	Arguments: none
	Returns: the object

=cut

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self->init();
    return $self;
}

=head2 init

	Description: Arg parser.  Initializes defaults, then parses options.
	Arguments: none
	Returns: none

=cut

sub init {
    my $self = shift;
    
    # first argument is a command, like so:
    # myinst.pl <command> -h <hosts> -j 4 <rest_of_args>
    my $command = shift @ARGV;
    unless( $command ) {
        print "command not found\n";
        $self->usage();
    }
    
    $self->{ opts } = {
        host            => '',
        hostfile        => '',
        parallel        => 1,
        save_to_file    => 0,
        directory       => '.',
        debug           => 0,
        command         => $command,
    };
    
    GetOptions(
        'h=s'       => \$self->{ opts }->{ host },
        'H=s'       => \$self->{ opts }->{ hostfile },
        'j=i'       => \$self->{ opts }->{ parallel },
        'f'         => \$self->{ opts }->{ save_to_file },
        'dir=s'     => \$self->{ opts }->{ directory },
        'd'         => sub { $self->{ opts }->{ debug }++ }, # for incremental debug levels, if needed
    );

    $self->{ pm } = Parallel::ForkManager->new( $self->{ opts }->{ parallel } );
    
    $self->{ opts }->{ args } = join( ' ', @ARGV );
    $self->usage() unless( (  $self->{ opts }->{ host } || -f $self->{ opts }->{ hostfile } ) && $self->{ opts }->{ args } );
    Log::Log4perl->easy_init($DEBUG) if $self->{ opts }->{ debug };
}

=head2 run

    Description: The driver method.  Determines the next action based on the options passed in.
    Arguments: none
    Returns: none

=cut

sub run {
    my $class = shift;
    my $self = $class->new();
    
    my $command = $self->{ opts }->{ command };
    my $method = "run_$command";
    $self->$method() if ( $self->can( $method ) );
}

=head2 run_ssh

    Description: Do the ssh command business.
    Arguments: none
    Returns: none, but can croak on errors

=cut

sub run_ssh {
    my $self = shift;

    my @hosts = $self->build_hosts();
    my $pm = $self->{ pm };

    for my $host ( @hosts ) {
        $pm->start and next;
        my $command = "ssh $host " . "\"$self->{ opts }->{ args }\"";
        DEBUG "host: $host, command: $command";
        my $ret;
    
        if ( $self->{ opts }->{ save_to_file } ) {
            my $file = $self->{ opts }->{ directory } . "/$host.log";
            DEBUG "saving to $file";
            my $output = `$command`;
            $ret = $? >> 8;
            open( my $fh, ">", $file ) or die "Could not open $file: $!";
            print $fh $output;
            close $fh or die "Could not close $file: $!";
        }
        else {
            system( $command );
            $ret = $? >> 8;
        }

        print "*** (myinst) something went wrong on $host ***\n" if ( $ret );
        $pm->finish;
    }
    $pm->wait_all_children;
}

=head2 build_hosts

    Description: Parses options, open files (if needed) and returns hostlist
    Arguments: none (object should have everything)
    Returns: array of hosts

=cut

sub build_hosts {
    my $self = shift;

    my $file = $self->{ opts }->{ hostfile };
    my @hosts;

    if ( -f $file ) {
        open( my $fh, "<", $file ) or die "Could not open $file: $!";
        chomp( @hosts = <$fh> );
        close $fh or die "Could not close $file: $!";
    }

    push @hosts, split( /,/, $self->{ opts }->{ host } ) if ( $self->{ opts }->{ host } );
    return @hosts;
}

=head2 usage

    Description: Prints usage and exits.
    Arguments: none
    Returns: none

=cut

sub usage {
    my $self = shift;

    print <<'USAGE';
Usage: ./myinst.pl <command> -h host1,host2 -j 4 "<remote_command>"
Implements very limited features of a legendary command-line tool at an iconic
internet company.

    <command>           command to myinst.  currently, only "ssh" is supported
    -h                  hostname, can be a comma-separated list with username like user@host
    -H                  specify a file with hostnames in it
    -j                  number of jobs to execute in parallel.  default: 1
    -f                  flag to save output in a file per host.  default: cwd
    -dir                if -f is specified, you may specify the output directory
    -d                  debug mode
    <remote_command>    the command to run on the remote hosts
USAGE
    exit(0);
}

=head1 AUTHOR

Satoshi Yagi, C<< <satoshi.yagi at yahoo.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-myinst at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Myinst>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Myinst


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Myinst>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Myinst>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Myinst>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Myinst/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Satoshi Yagi.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of App::Myinst
