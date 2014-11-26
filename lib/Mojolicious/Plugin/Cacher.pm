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
        'before_dispatch' => sub {
            my  $c = shift ;
            my $path = $c->tx->req->url->path;
            return if $path !~ /\/list$/ ;

            my $lang = Utils::Languages::current($c);
            my $unique_path = "$path/$lang";
            warn $unique_path;
#            $app->log->debug( ref $path );
#            if ( $cache->is_valid($path) ) {
#                $app->log->debug("serving from cache for $path");
#                my $data = $cache->get($path);
#                $c->res->code( $data->{code} );
#                $c->res->headers( $data->{headers} );
#                $c->res->body( $data->{body} );
#                $c->stash( 'from_cache' => 1 );
#            }
        }
    );
};

};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut

