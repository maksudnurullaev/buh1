package Buh1::User; {
use Mojo::Base 'Mojolicious::Controller';

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
                $self->session->{'user'} = $name;
                $self->redirect_to('/'); 
                return;
            } else { $error_found = 1; }
        }
    }
    $self->stash(error => 1) if $error_found ;
    $self->render();
};

sub logout{
    my $self = shift;
    delete $self->session->{'user'};
    $self->redirect_to('/');
};

1;

};
