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
use Utils::Cacher;

my $actions; # useless awhile
my @cache_conf_defaults = ('driver' => 'Memory', global => 1);

sub register {
    my ($self,$app, $conf) = @_;
    my $cache = get_cache();
    
    if ( defined $conf->{actions} ) { # useless awhile
        $actions = { map { $_ => 1 } @{ $conf->{actions} } };
    }

    #setup cache
    if ( !$cache ) {
        if ( defined $conf->{options} ) {
            my $opt = $conf->{options};
            $opt->{driver} = $self->driver if not defined $opt->{driver};
            $cache = set_cache(CHI->new(%$opt));
        }
        else {
            $cache = set_cache(CHI->new( @cache_conf_defaults ));
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
            warn "CACHE <-- $cache_path";
        }
    );
};

};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut

