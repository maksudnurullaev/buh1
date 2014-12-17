package Buh1::Feedbacks; {
use Mojo::Base 'Mojolicious::Controller';
use Auth;
use Data::Dumper;
use Utils::Filter;

my $OBJECT_NAME         = 'feedback';
my $OBJECT_NAMES        = 'feedbacks';
my $DELETED_OBJECT_NAME = 'deleted feedbacks';

sub redirect2list_or_path{
    my $self = shift;
    if ( $self->param('path') ){
        $self->redirect_to($self->param('path'));
        return;
    }
    $self->redirect_to("/$OBJECT_NAMES/list");
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

    select_objects($self,$OBJECT_NAME,'');
};

sub deleted{
    my $self = shift;

    select_objects($self,$DELETED_OBJECT_NAME,"/$OBJECT_NAMES/deleted");
};

sub select_objects{
    my ($self,$name,$path) = @_;

    my $db = Db->new($self);
    my $filter    = $self->session->{"$OBJECT_NAMES/filter"};
    my $objects = $db->get_filtered_objects({
            self          => $self,
            name          => $name,
            names         => $OBJECT_NAMES,
            exist_field   => 'message',
            filter_value  => $filter,
            result_fields => ['message','user','contact'],
            path          => "/$OBJECT_NAMES/deleted"
        });
    $self->stash(path  => $path);
    $self->stash($OBJECT_NAMES => $objects) if $objects && scalar(keys %{$objects});
};

sub restore{
    my $self = shift;

    my $id = $self->param('payload');
    if( $id ){
        my $db = Db->new($self);
        $db->change_name($OBJECT_NAME, $id);
    } else {
        warn "$OBJECT_NAMES:restore:error $OBJECT_NAME id not defined!"; 
    }
    $self->redirect_to("/$OBJECT_NAMES/deleted");
};

sub validate{
    my $self = shift;
    my $user = Utils::User::current($self);
    my $data = { object_name => $OBJECT_NAME };
    if( $user ){
        $data->{user} = $user;
    } else {
        my($user,$contact) = ( Utils::trim($self->param('user')),
            Utils::trim($self->param('contact')) );
        $data->{user}    = $self->param('user')    if $user;
        $data->{contact} = $self->param('contact') if $contact;
    }
    $data->{message} = Utils::trim $self->param('message');

    if( !$data->{message} ){ 
       $data->{error} = 1; 
       $self->stash(message_class => "error"); 
    }

    return($data);
};

sub del{
    my $self = shift;

    my $id = $self->param('payload');
    if( $id ){
        my $db = Db->new($self);
        $db->change_name($DELETED_OBJECT_NAME, $id);
    } else {
        warn "$OBJECT_NAMES:delete:error $OBJECT_NAME id not defined!"; 
    }
    $self->redirect_to("/$OBJECT_NAMES/list");
};

sub edit{
    my $self = shift;

    $self->stash(edit_mode => 1);
    my $method = $self->req->method;
    my $data;
    my $id = $self->param('payload');
    if( !$id) { 
        $self->redirect_to("/$OBJECT_NAMES/list"); 
        warn "$OBJECT_NAMES:edit:error $OBJECT_NAME id not defined!";
        return; 
    }
    my $db = Db->new($self);
    if ( $method =~ /POST/ ){
        $data = validate( $self );
        if( !exists($data->{error}) ){
            delete $data->{creator}; # creator already exists!
            $data->{id} = $id;
            if( $db->update($data) ){
                $self->stash(success => 1);
            } else {
                $self->stash(error => 1);
                warn "$OBJECT_NAMES:edit:ERROR: could not update $OBJECT_NAME!";
            }
        } else {
            $self->stash(error => 1);
        }
    } 
    $data = $db->get_objects({id=>[$id]});
    if( $data ){
        for my $key (keys %{$data->{$id}} ){
            $self->stash($key => $data->{$id}->{$key});
        }
    } else {
        redirect_to("/$OBJECT_NAMES/list");
    }
    $self->render("$OBJECT_NAMES/add");
};

sub add{
    my $self = shift;

    my $method = $self->req->method;
    if ( $method =~ /POST/ ){
        # check values
        my $data = validate( $self );
        # add
        if( !exists($data->{error}) ){
            my $db = Db->new($self);
            if( $db->insert($data) ){
                $self->stash(success => 1);
            } else {
                warn "$OBJECT_NAMES:add:error: could not add new one!";
            }
        } else {
            $self->stash(error => 1);
        }
    }
    $self->render();
};

1;

};
