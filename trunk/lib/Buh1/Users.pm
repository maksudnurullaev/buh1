package Buh1::Users; {
use Mojo::Base 'Mojolicious::Controller';
use Auth;
use Data::Dumper;
use Utils::Filter;

my $OBJECT_NAME         = 'user';
my $OBJECT_NAMES        = 'users';
my $DELETED_OBJECT_NAME = 'deleted user';

sub redirect2list_or_path{
    my $self = shift;
    if ( $self->param('path') ){
        $self->redirect_to($self->param('path'));
        return;
    }
    $self->redirect_to("$OBJECT_NAMES/list");
};

sub pagesize{
    my $self = shift;
    Utils::Filter::pagesize($self,$OBJECT_NAMES);
    redirect2list_or_path($self);
};

sub page{
    my $self = shift;
    Utils::Filter::page($self,$OBJECT_NAMES);
    redirect2list_or_path($self);
};

sub nofilter{
    my $self = shift;
    Utils::Filter::nofilter($self,"$OBJECT_NAMES/filter");
    redirect2list_or_path($self);
};

sub filter{
    my $self = shift;
    Utils::Filter::filter($self,$OBJECT_NAMES);
    redirect2list_or_path($self);
};

sub select_objects{
    my ($self,$name,$path) = @_;

    my $filter    = $self->session->{"$OBJECT_NAMES/filter"};
    my $objects = Utils::Filter::get_objects({
            self          => $self,
            name          => $name,
            names         => $OBJECT_NAMES,
            filter        => $filter,
            filter_field  => 'email',
            result_fields => ['email','description'],
            path          => '/users/deleted'
        });
    $self->stash(path  => $path);
    $self->stash(users => $objects) if $objects && scalar(keys %{$objects});
    Db::attach_links($objects,'companies','company',['name']);
    for my $uid (keys %{$objects}){
        if ( exists $objects->{$uid}{companies} ){
            my $companies = $objects->{$uid}{companies};
            for my $cid (keys %{$companies}){
                $companies->{$cid}{access} = Db::get_linked_value('access',$cid,$uid);
            }
        }
    }
    return($objects);
};

sub list{
    my $self = shift;
    return if !$self->is_admin;
    select_objects($self,$OBJECT_NAME,'');
};

sub deleted{
    my $self = shift;
    return if !$self->is_admin;
    select_objects($self,$DELETED_OBJECT_NAME,'/users/deleted');
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

sub validate_email{
    my $email = shift;
    return(0) if ( !$email || !Utils::validate_email($email) );
    return(0) if ( Db::get_user($email) );
    return(1);
};

sub validate{
    my $self = shift;
    my $edit_mode = shift;
    my $data = { 
        object_name => $OBJECT_NAME,
        creator => Utils::User::current($self),
        extended_right => $self->param('extended_right')
    };
    if( !$edit_mode ) {
        $data->{email} = Utils::trim $self->param('email');
        if( !validate_email($data->{email}) ){
            $data->{error} = 1;
            $self->stash(email_class => "error");
        }
    }
    $data->{description} = Utils::trim $self->param('description')
        if Utils::trim $self->param('description');
    $data->{password1} = Utils::trim $self->param('password1');
    $data->{password2} = Utils::trim $self->param('password2');
    if( $edit_mode && !$data->{password1} && !$data->{password2} ){
        delete $data->{password1};
        delete $data->{password2};
        return($data);
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

sub remove_company{
    my $self = shift;
    return if !$self->is_admin;

    my $user_id      = $self->param('payload');
    my $id = $self->param('company');
    Db::del_link($id,$user_id);
    Db::del_linked_value('access',$id,$user_id);
    $self->redirect_to("/users/edit/$user_id");
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
        $data = validate( $self, 1 );
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
        Db::attach_links($data,'companies','company',['name']);
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
        my $data = validate( $self, 0 );
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
