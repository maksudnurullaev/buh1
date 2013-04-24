package Buh1::Users; {
use Mojo::Base 'Mojolicious::Controller';
use Auth;

my $OBJECT_NAME = 'user';
my $DELETED_OBJECT_NAME = 'deleted user';

sub list{
    my $self = shift;
    return if !$self->is_admin;
    my $users = Db::get_objects({name=>[$OBJECT_NAME]});
    $self->stash(users => $users);
    $self->render();
};

sub deleted{
    my $self = shift;
    return if !$self->is_admin;
    my $users = Db::get_objects({name=>[$DELETED_OBJECT_NAME]});
    $self->stash(users => $users);
};

sub restore{
    my $self = shift;
    return if !$self->is_admin;
    my $id = $self->param('payload');
    if( $id ){
        Db::change_name($OBJECT_NAME, $id);
    } else {
        warn "Users:restore:error user id not defined!"; 
    }
    $self->redirect_to('users/deleted');
};

sub validate_passwords{
    my $self = shift;
    my $data = shift;
    if( !Utils::validate_passwords($data->{password1}, $data->{password2}) ){
        $data->{error} = 1;
        $self->stash(password1_class => "error");
        $self->stash(password2_class => "error");
    } else {
        $data->{password} = Auth::salted_password($data->{password1});
        delete $data->{password1};
        delete $data->{password2};
    }
};

sub validate4update{
    my $self = shift;
    my $edit_mode = shift;
    my $data = { 
        object_name => $OBJECT_NAME,
        updater => Utils::User::current($self) };
    $data->{email} = Utils::trim $self->param('email');
    $data->{password1} = Utils::trim $self->param('password1');
    $data->{password2} = Utils::trim $self->param('password2');
    $data->{description} = Utils::trim $self->param('description')
        if Utils::trim $self->param('description');

    if(    !$data->{email}
        || !Utils::validate_email($data->{email}) ){ 
        $data->{error} = 1;
        $self->stash(email_class => "error");
    }

    return($data) if( !$data->{password1} && !$data->{password2} );
    validate_passwords($self,$data);
    return($data);
};

sub validate{
    my $self = shift;
    my $edit_mode = shift;
    my $data = { 
        object_name => $OBJECT_NAME,
        creator => Utils::User::current($self) };
    $data->{email} = Utils::trim $self->param('email');
    $data->{description} = Utils::trim $self->param('description')
        if Utils::trim $self->param('description');
    $data->{password1} = Utils::trim $self->param('password1');
    $data->{password2} = Utils::trim $self->param('password2');
    if(    !$data->{email}
        || !Utils::validate_email($data->{email}) ){ 
        $data->{error} = 1;
        $self->stash(email_class => "error");
    }
    validate_passwords($self, $data);
    return($data);
};

sub del{
    my $self = shift;
    return if !$self->is_admin;
    my $id = $self->param('payload');
    if( $id ){
        Db::change_name($DELETED_OBJECT_NAME, $id);
    } else {
        warn "Users:delete:error user id not defined!"; 
    }
    $self->redirect_to('users/list');
};

sub edit{
    my $self = shift;
    return if !$self->is_admin;

    $self->stash(edit_mode => 1);
    my $method = $self->req->method;
    my $data;
    my $id = $self->param('payload');
    if( !$id) { 
        $self->redirect_to('users/list'); 
        warn "Users:edit:error user id not defined!";
        return; 
    }
    if ( $method =~ /POST/ ){
        $data = validate4update( $self );
        if( !exists($data->{error}) ){
            $data->{id} = $id;
            if( Db::update($data) ){
                $self->stash(success => 1);
            } else {
                $self->stash(error => 1);
                warn 'Users:edit:ERROR: could not update user!';
            }
        } else {
            $self->stash(error => 1);
        }
    } 
    $data = Db::get_objects({id=>[$id]});
    if( $data ){
        for my $key (keys %{$data->{$id}} ){
            $self->stash($key => $data->{$id}->{$key});
        }
    } else {
        redirect_to('users/list');
    }
    $self->render('users/add');
};

sub add{
    my $self = shift;
    return if !$self->is_admin;

    my $method = $self->req->method;
    if ( $method =~ /POST/ ){
        # check values
        my $data = validate( $self );
        # add
        if( !exists($data->{error}) ){
            if( Db::insert($data) ){
                $self->redirect_to('users/list');
            } else {
                $self->stash(error => 1);
                warn 'Users:add:error: could not add new user!';
            }
        } else {
            $self->stash(error => 1);
        }
    }
    $self->render();
};

1;

};
