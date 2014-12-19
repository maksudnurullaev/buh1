package Buh1::User; {
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;

sub authorized2password{
    my $self = shift ;
    if( $self->who_is_global('guest') ){
        $self->redirect_to('/user/login?warning=access');
        return(0);
    }
    return(1);
};


sub login{
    my $self = shift;
    my $method = $self->req->method;
    my $error_found = 0;
    if ( $method =~ /POST/ ){
        my $email = Utils::trim $self->param('email');
        if ( !$email || $email =~ /[^\x00-\xFF]/ ) { $error_found = 1; $self->stash(email_class => "error")};
        my $password = Utils::trim $self->param('password');
        if ( !$password || $password =~ /[^\x00-\xFF]/ ) { $error_found = 1; $self->stash(password_class => "error")};
        if (!$error_found){
            if ( my $user = Auth::login($self, $email, $password) ){ 
                $self->session->{'user email'} = $email;
                if( $email =~ /^admin$/i ){
                    $self->session->{'user id'} = $user;
                } else {
                    $self->session->{'user id'} = $user->{id};
                }
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
    $self->session(expires => 1);
    $self->redirect_to('/');
};

sub password{
    my $self = shift;
    return if !authorized2password($self) ;

    my $email = Utils::User::current($self);
    my $method = $self->req->method;
    my $error_found = 0;
    if ( $method =~ /post/i ){
        $self->stash(post => 1);
        # check for valid values
        my $password = $self->param('password');
        if (!$password) { $error_found = 1; $self->stash(password_class => "error")};
        my $password1 = $self->param('password1');
        if (!$password1) { $error_found = 1; $self->stash(password1_class => "error")};
        my $password2 = $self->param('password2');
        if (!$password2) { $error_found = 1; $self->stash(password2_class => "error")};
        # check for password1 and password2 equality
        if( !Utils::validate_passwords($password1, $password2, $password) ){ 
            $error_found = 1;
            $self->stash(password1_class => "error");
            $self->stash(password2_class => "error");
        }
        # check for email and password
        if ( !Auth::login($self, $email, $password) ){ 
            $error_found = 1; 
            $self->stash(password_class => "error")
        }
        # prevent change password for demo@buh1.uz 
        if( lc($email) eq 'demo@buh1.uz' ){
            $error_found = 1;
            $self->stash( error_message => $self->ml('You could not change password for demo@buh1.uz') );
        }
        # FINAL ACTION - change password if no errors
        if( !$error_found ){
            if(Auth::set_password($self,$email,$password1)){
                $self->stash(success => 1);
            } else {
                $error_found = 1;
            }
        }

    }
    $self->stash(error => 1) if $error_found ;
};

1;

};
