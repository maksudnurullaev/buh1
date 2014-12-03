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
our @EXPORT = qw(get_cache cache_it is_cached clear_cache);

my @cache_conf_defaults = ('driver' => 'Memory', global => 1);

our $cache;
our $cacher = {};

sub get_cache{ 
    my $cache_namespace = 'global';
    return $cacher->{$cache_namespace} if exists $cacher->{$cache_namespace};
    $cacher->{$cache_namespace} = CHI->new( @cache_conf_defaults );
    return $cacher->{$cache_namespace}; 
};

sub generate_key{
    my ($c,$name) = @_;
    die "Could not generate cache key!" if !$c || !$name ;

    my $key = 
        $c->stash('controller') 
        . '.' . $c->stash('action') 
        . '.' . $name 
        . '.' . Utils::Languages::current($c);
    
};

sub cache_it{
    my ($c,$name,$value) = @_ ;
    die "Nothing to cache" if !$name || !$value;

    $name = generate_key($c, $name);
    my $cache = get_cache ;
    $cache->set($name, $value);
    warn "CACHE <-- ($name)";
};

sub is_cached{
    my ($c,$name) = @_ ;
    die "Nothing to cache" if !$name;

    $name = generate_key($c, $name);
    my $cache = get_cache ;
    warn "CACHE --> ($name)" if $cache->is_valid($name);
    return $cache->get($name);
};

sub clear_cache{
    my $c = shift;
    my $start_key = $c->stash('controller');
    my @del_keys = ();
    my $cache = get_cache ;
    my $cache_keys = $cache->get_keys();

    push @del_keys, grep {/^$start_key/} $cache->get_keys();
    $cache->remove_multi(\@del_keys);
    warn "CACHE >X< (@del_keys)" ;
};

};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut

