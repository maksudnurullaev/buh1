package Buh1::Initial;
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

sub login{
    my $self = shift;
    my $method = $self->req->method;
    my $error_found = 0;
    if ( $method =~ /POST/ ){
        my $name = Utils::trim $self->param('name');
        if (!$name) { $error_found = 1; $self->stash(name_class => "error")};
        my $password = Utils::trim $self->param('password');
        if (!$password) { $error_found = 1; $self->stash(password_class => "error")};
        if (!$error_found){
            if ( Auth::login($name, $password) ){ 
                $self->redirect_to('/'); 
                return;
            } else { $error_found = 1; }
        }
    }
    $self->stash(error => 1) if $error_found ;
    $self->render();
};

1;
