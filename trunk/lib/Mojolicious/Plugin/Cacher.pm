package Mojolicious::Plugin::Cacher; {

=encoding utf8


=head1 NAME

    Cacher used to implement web pages caching technics

=head1 USAGE

    Details add soon...

=cut

use 5.012000;
use strict;
use warnings;
use utf8;
use base 'Mojolicious::Plugin';
use File::Path qw/make_path/;
use Carp;
use Data::Dumper;

sub register {
    my ($self,$app, $conf) = @_;

    # define cacher directory
    my $cache_dir = $app->home->rel_dir('_CACHE');
    make_path($cache_dir) if ! -e $cache_dir ;
    # ... if still not create working directory for cacher
    croak "Could not create working directory fo Caher!" if ! -e $cache_dir;

    # warn Dumper $conf; 
};

};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut

