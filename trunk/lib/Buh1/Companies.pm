package Buh1::Companies; {
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;

my $OBJECT_NAME = 'company';
my $USER_OBJECT_NAME = 'user';
my $DELETED_OBJECT_NAME = 'deleted company';

sub list{
    my $self = shift;
    return if !$self->is_admin;
    my $companies = Db::get_objects({name=>['company'],field=>['name','description']});
    Db::attach_links($companies,'users','user',['email']);
    $self->stash(companies => $companies);
    $self->render();
};

sub deleted{
    my $self = shift;
    return if !$self->is_admin;
    my $companies = Db::get_objects({name=>[$DELETED_OBJECT_NAME]});
    $self->stash(companies => $companies);
    $self->render();
};

sub restore{
    my $self = shift;
    return if !$self->is_admin;
    my $id = $self->param('payload');
    if( $id ){
        Db::change_name($OBJECT_NAME, $id);
    } else {
        warn "Companies:restore:error company id not defined!"; 
    }
    $self->redirect_to('companies/deleted');
};

sub validate{
    my $self = shift;
    my $data = { 
        object_name => $OBJECT_NAME,
        creator => Utils::User::current($self) };
    $data->{name}   = Utils::trim $self->param('name');
    $data->{access} = $self->param('access');
    if(!$data->{name}){ 
        $data->{error} = 1;
        $self->stash(name_class => "error");
    }
    $data->{description} = Utils::trim $self->param('description')
        if Utils::trim $self->param('description');
    return($data);
};

sub del{
    my $self = shift;
    return if !$self->is_admin;
    my $id = $self->param('payload');
    if( $id ){
        Db::change_name($DELETED_OBJECT_NAME, $id);
    } else {
        warn "Companies:delete:error company id not defined!"; 
    }
    $self->redirect_to('companies/list');
};

sub remove_user{
    my $self = shift;
    return if !$self->is_admin;

    my $id      = $self->param('payload');
    my $user_id = $self->param('user');
    Db::del_link($id,$user_id);
    $self->redirect_to("companies/edit/$id");
};

sub add_user{
    my $self = shift;
    return if !$self->is_admin;

    my $id      = $self->param('payload');
    my $user_id = $self->param('user');
    Db::set_link($OBJECT_NAME,$id,$USER_OBJECT_NAME,$user_id);
    $self->redirect_to("companies/edit/$id");
};

sub edit{
    my $self = shift;
    return if !$self->is_admin;

    $self->stash(edit_mode => 1);
    my $method = $self->req->method;
    my $data;
    my $id = $self->param('payload');
    if( !$id) { 
        $self->redirect_to('companies/list'); 
        warn "Companies:edit:error company id not defined!";
        return; 
    }
    if ( $method =~ /POST/ ){
        $data = validate( $self );
        if( !exists($data->{error}) ){
            warn $data->{'access'};
            $data->{id} = $id;
            if( Db::update($data) ){
                $self->stash(success => 1);
            } else {
                $self->stash(error => 1);
                warn 'Companies:edit:ERROR: could not update company!';
            }
        } else {
            $self->stash(error => 1);
        }
    } 

    my $all_users = Db::get_objects({name=>[$USER_OBJECT_NAME]});
    my $linked_users = Db::get_links($id, $USER_OBJECT_NAME);
    my ($company_users,$users) = ([],[]);
    for my $user_id( keys %{$linked_users}){
        push @{$company_users}, [$linked_users->{$user_id}->{email} => $user_id]
            if exists($all_users->{$user_id});
    }
    for my $user_id(keys %{$all_users}){
        push @{$users}, [$all_users->{$user_id}->{email} => $user_id]
            if !exists($linked_users->{$user_id}) ;
    }
    $self->stash(users => $users) if @{$users};
    $self->stash(company_users => $company_users) if @{$company_users};

    if( $data = Db::get_objects({id=>[$id]}) ){
        for my $key (keys %{$data->{$id}} ){
            $self->stash($key => $data->{$id}->{$key});
        }
    } else {
        redirect_to('companies/list');
    }
    $self->render('companies/add');
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
                $self->redirect_to('companies/list');
            } else {
                $self->stash(error => 1);
                warn 'Companies:add:ERROR: could not add new company!';
            }
        } else {
            $self->stash(error => 1);
        }
    }
    $self->render();
};

1;

};
