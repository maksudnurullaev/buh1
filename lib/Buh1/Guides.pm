package Buh1::Guides; {

=encoding utf8

=head1 NAME

    Accounts controller

=cut

use Mojo::Base 'Mojolicious::Controller';
use Utils::Guides ;
use Utils::Files ;
use Utils ;
use Encode qw( encode decode_utf8 );
use Data::Dumper ;

sub page{
    my $self = shift;
    $self->stash( guides => Utils::Guides::get_list($self) ) ;
};

sub add{
    my $self = shift ;
    if( !$self->is_admin ){
        $self->redirect_to('/guides/page');
        return;
    }
    if ( $self->req->method =~ /POST/ ){
        if( Utils::Guides::add_file($self) ){
            $self->stash(success => 1);
            $self->redirect_to('/guides/page');
        } else {
            $self->stash(error => 1);
        }
	}
};


# END OF PACKAGE

};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
