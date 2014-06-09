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
use Text::CSV_XS qw( csv );

sub page{
    my $self = shift;
    $self->stash( guides => Utils::Guides::get_list($self) ) ;
};

sub is_editor{
    my $self = shift ;
    if( !$self->is_admin ){
        $self->redirect_to('/guides/page');
        return(0);
    }
    return(1);
};

sub add{
    my $self = shift ;
    return if !is_editor($self);

    if ( $self->req->method =~ /POST/ ){
        if( my $guide_number = Utils::Guides::add_guide($self) ){
            $self->stash(success => 1);
            $self->redirect_to("/guides/edit/$guide_number");
        } else {
            $self->stash(error => 1);
        }
	}
};

sub edit{
    my $self                 = shift;
    my $guide_number         = $self->param('payload');

    if ( $self->req->method =~ /POST/ ){
        if( Utils::Guides::update_guide($self) ){
            $self->stash(success => 1);
            $self->redirect_to("/guides/edit/$guide_number");
        } else {
            $self->stash(error => 1);
            return;
        }
	}
    #Final
    Utils::Guides::deploy_guide($self,$guide_number);
};


# END OF PACKAGE

};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
