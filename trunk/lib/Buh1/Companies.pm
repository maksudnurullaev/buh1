package Buh1::Companies; {
use Mojo::Base 'Mojolicious::Controller';

sub list{
    my $self = shift;
    return if !$self->is_admin;
    $self->render();
};

sub add{
    my $self = shift;
    return if !$self->is_admin;
    $self->render();
};

1;

};
