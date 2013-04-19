package Buh1::Companies; {
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;

my $OBJECT_NAME = 'company';
my $USER_OBJECT_NAME = 'user';
my $DELETED_OBJECT_NAME = 'deleted company';

sub list{
    my $self = shift;
    return if !$self->is_admin;
    my $companies = Db::select_distinct_many(" WHERE name='$OBJECT_NAME' ");
    $self->stash(companies => $companies);
    $self->render();
};

sub deleted{
    my $self = shift;
    return if !$self->is_admin;
    my $companies = Db::select_distinct_many(" WHERE name='$DELETED_OBJECT_NAME' ");
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
    $data->{name} = Utils::trim $self->param('name');
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

    my $user_objects = Db::select_distinct_many(" WHERE name='$USER_OBJECT_NAME' ");
    my $users = [];
    for my $user_id(keys %{$user_objects}){
        push @{$users}, [$user_objects->{$user_id}->{email} => $user_id];
    }
    $self->stash(users => $users);

    if( $data = Db::get_object($id) ){
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
