package Buh1::Initial; {
use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub welcome {
    my $self = shift;
    $self->render();
}

sub lang{
    my $self = shift;
    my $lang = $self->param('id');
    $self->session->{'lang'} = $lang;
    $self->redirect_to('/');
};

1;

};
