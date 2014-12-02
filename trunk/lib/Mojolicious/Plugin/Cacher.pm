package Mojolicious::Plugin::Cacher; {

=encoding utf8


=head1 NAME

    Cacher used to implement web pages caching technics

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
use Data::Dumper;

my $actions;
my $cache;
my @cache_conf_defaults = ('driver' => 'Memory', global => 1);

sub register {
    my ($self,$app, $conf) = @_;
    
    if ( defined $conf->{actions} ) {
        $actions = { map { $_ => 1 } @{ $conf->{actions} } };
    }

    #setup cache
    if ( !$cache ) {
        if ( defined $conf->{options} ) {
            my $opt = $conf->{options};
            $opt->{driver} = $self->driver if not defined $opt->{driver};
            $cache = CHI->new(%$opt);
        }
        else {
            $cache = CHI->new( @cache_conf_defaults );
        }
    }

    if ( $app->log->level eq 'debug' ) {
        $cache->on_set_error('log');
        $cache->on_get_error('log');
    }

    $app->hook(
        'after_dispatch' => sub {
            my ( $c ) = @_;
            my $cache_path = is_cachable($c);
            return if !$cache_path;
 
            ## - has to be GET request
            return if $c->req->method ne 'GET';
 
            ## - only successful response
            return if $c->res->code != 200;
            return if !$c->stash('from_cache');
            return if $c->stash('from_cache') != -1 ;

            $cache->set(
                $cache_path,
                {   body    => $c->res->body,
                    headers => $c->res->headers,
                    code    => $c->res->code
                }
            );
        }
    );
};

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

};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut

