package Utils::Cacher; {

=encoding utf8


=head1 NAME

    Cacher utils

=head1 USAGE

    Details dd soon...

=cut

use 5.012000;
use strict;
use warnings;
use utf8;
use base 'Mojolicious::Plugin';
use File::Path qw/make_path/;
use Carp;
use CHI;
use Utils::Languages;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(cache_it is_cached clear_cache);

my @cache_conf_defaults = ('driver' => 'Memory', global => 1);

our $cache;
our $cacher = {};

sub get_cache{ 
    my $cache_namespace = shift;
    return $cacher->{$cache_namespace} if exists $cacher->{$cache_namespace};
    $cacher->{$cache_namespace} = CHI->new( @cache_conf_defaults );
    return $cacher->{$cache_namespace}; 
};

sub cache_it{
    my ($c,$name,$value) = @_ ;
    my $cache_namespace = $c->stash('controller') ;
    my $cache = get_cache $cache_namespace;
    $cache->set($name, $value);
    warn "CACHE <-- ($cache_namespace,$name)";
};

sub is_cached{
    my ($c,$name) = @_ ;
    my $cache_namespace = $c->stash('controller') ;
    my $cache = get_cache $cache_namespace;
    warn "namespace = $cache_namespace, name = $name";
    warn "CACHE --> ($cache_namespace,$name)" if $cache->is_valid($name);
    return $cache->get($name);
};

sub clear_cache{
    my $c = shift ;
    my $cache_namespace = $c->stash('controller') ;
    my $cache = get_cache $cache_namespace;
    $cache->clear();
    warn "CACHE >X< ($cache_namespace)" ;
};

};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut

