package Buh1::User; {
use Mojo::Base 'Mojolicious::Controller';

sub login{
    my $self = shift;
    my $method = $self->req->method;
    my $error_found = 0;
    if ( $method =~ /POST/ ){
        my $user = Utils::trim $self->param('user');
        if (!$user) { $error_found = 1; $self->stash(user_class => "error")};
        my $password = Utils::trim $self->param('password');
        if (!$password) { $error_found = 1; $self->stash(password_class => "error")};
        if (!$error_found){
            if ( Auth::login($user, $password) ){ 
                $self->session->{'user'} = $user;
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

sub password{
    my $self = shift;
    return if !$self->is_user;
    my $user = Utils::User::current($self);
    my $method = $self->req->method;
    my $error_found = 0;
    if ( $method =~ /POST/ ){
        $self->stash(post => 1);
        # stage 1 - check for valid values
        my $password = Utils::trim $self->param('password');
        if (!$password) { $error_found = 1; $self->stash(password_class => "error")};
        my $password1 = Utils::trim $self->param('password1');
        if (!$password1) { $error_found = 1; $self->stash(password1_class => "error")};
        my $password2 = Utils::trim $self->param('password2');
        if (!$password2) { $error_found = 1; $self->stash(password2_class => "error")};

        # stage 2 - check for password1 and password2 equality
        if( !$password1 
            || !$password2 
            || ($password1 ne $password2) ){
            $error_found = 1;
            warn "ERRORmme";
            $self->stash(password1_class => "error");
            $self->stash(password2_class => "error");
        }
        # stage 3 - check for user and password
        if ( !Auth::login($user, $password) ){ 
            $error_found = 1; 
            $self->stash(password_class => "error")
        }
        # stage 4 - final, change password
        if( !$error_found ){
            if(Auth::set_password($user,$password1)){
                $self->stash(success => 1);
            } else {
                $error_found = 1;
            }
        }
    }
    $self->stash(error => 1) if $error_found ;
    $self->render();
};

1;

};
