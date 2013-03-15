package Buh1::Initial;
use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub welcome {
    my $self = shift;
    $self->render();
}

sub locale{
    my $self = shift;
    my $lang = $self->param('lang');
    $self->session->{'lang'} = $lang;
    $self->redirect_to("/");
};

1;
