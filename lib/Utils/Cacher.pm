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
our @EXPORT = qw(cache_it is_cachable get_cache set_cache clear_cache);

our $cache;

sub get_cache{ return($cache); } ;
sub set_cache{ $cache = shift; } ;

sub cache_it{
    my $c = shift ;
    my $cache_path = is_cachable($c);
    return if !$cache_path;
    if( $cache->is_valid($cache_path) ){
        my $data = $cache->get($cache_path);
        $c->res->code( $data->{code} );
        $c->res->headers( $data->{headers} );
        $c->res->body( $data->{body} );
        $c->rendered ;
        warn "CACHE --> $cache_path";
        return(1);
    }
    $c->stash( from_cache => -1 );
    return(0);
};

sub is_cachable{
    my $c = shift;
    return if !$c;
    my $path = $c->tx->req->url->path->to_string();
    return if $path !~ /list\/?$/ ;
    my $lang = Utils::Languages::current($c);
    return( $path =~ /\/$/ ? ($path . $lang) : "$path/$lang" );
};

sub clear_cache{
    my $c = shift;
    my $cache_path = '/' . $c->stash('controller') . '/list/' 
            . Utils::Languages::current($c);
    warn "CACHE X> $cache_path";
    if( $cache && 
        $cache->is_valid($cache_path) ){
        $cache->remove($cache_path);    
        warn "CACHE XX> $cache_path";
    }
}

};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut

