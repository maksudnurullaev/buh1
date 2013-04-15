package Buh1::Companies; {
use Mojo::Base 'Mojolicious::Controller';

my $OBJECT_NAME = 'company';
sub list{
    my $self = shift;
    return if !$self->is_admin;
    my $companies = Db::select_distinct_many(" WHERE name='$OBJECT_NAME' ORDER BY id DESC ");
    $self->stash(companies => $companies);
    $self->render();
};

sub edit{

};

sub validate{
    my $self = shift;
    my $data = { object_name => $OBJECT_NAME };
    $data->{name} = Utils::trim $self->param('name');
    if(!$data->{name}){ 
        $data->{error} = 1;
        $self->stash(name_class => "error");
    }
    $data->{description} = Utils::trim $self->param('description')
        if Utils::trim $self->param('description');
    return($data);
};

sub add{
    my $self = shift;
    return if !$self->is_admin;

    my $user = Utils::User::current($self);
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
