package Buh1::Companies; {
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;
use Utils::Filter;

my $OBJECT_NAME         = 'company';
my $OBJECT_NAMES        = 'companies';
my $DELETED_OBJECT_NAME = 'deleted company';

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

sub list{
    my $self = shift;
    return if !$self->is_admin;
    select_objects($self,$OBJECT_NAME,'');
};

sub deleted{
    my $self = shift;
    return if !$self->is_admin;
    select_objects($self,$DELETED_OBJECT_NAME,'/companies/deleted');
};

sub select_objects{
    my ($self,$name,$path) = @_;

    my $filter    = $self->session->{"$OBJECT_NAMES/filter"};
    my $objects = Utils::Filter::get_objects({
            self          => $self,
            name          => $name,
            names         => $OBJECT_NAMES,
            filter        => $filter,
            filter_field  => 'name',
            result_fields => ['name','access','description']      
        });
    $self->stash(path  => $path);
    $self->stash(companies => $objects) if $objects && scalar(keys %{$objects});
    Db::attach_links($objects,'users','user',['email']);
    return($objects);
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
    Db::set_link($OBJECT_NAME,$id,'user',$user_id);
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

    my ($non_company_users,$company_users) = 
        Db::get_difference($id,'user','email');
    $self->stash(non_company_users => $non_company_users) if @{$non_company_users};
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
