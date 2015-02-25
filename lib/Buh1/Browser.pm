package Buh1::Browser; {

use Mojo::Base 'Mojolicious::Controller';

sub mobile {
    my $self   = shift;
    my $mobile = $self->param('payload'); 
    $self->session->{mobile} = $mobile ;
    $self->redirect_to('/');
}

1;

};
