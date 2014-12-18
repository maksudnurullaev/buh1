package Buh1::Feedbacks; {
use Mojo::Base 'Mojolicious::Controller';
use Auth;
use Utils;
use Utils::Filter;
use Utils::Feedbacks;

my $OBJECT_NAME         = 'feedback';
my $OBJECT_NAMES        = 'feedbacks';
my $DELETED_OBJECT_NAME = 'deleted feedbacks';

sub pagesize{
    my $self = shift;
    Utils::Filter::pagesize($self,$OBJECT_NAMES);
    Utils::redirect2list_or_path($self,$OBJECT_NAMES);
};

sub page{
    my $self = shift;
    Utils::Filter::page($self,$OBJECT_NAMES);
    Utils::redirect2list_or_path($self,$OBJECT_NAMES);
};

sub nofilter{
    my $self = shift;
    Utils::Filter::nofilter($self,"$OBJECT_NAMES/filter");
    Utils::redirect2list_or_path($self,$OBJECT_NAMES);
};

sub filter{
    my $self = shift;
    Utils::Filter::filter($self,$OBJECT_NAMES);
    Utils::redirect2list_or_path($self,$OBJECT_NAMES);
};

sub list{
    my $self = shift;
    return if !Utils::Feedbacks::authorized($self);
    select_objects($self,$OBJECT_NAME,'');
};

sub deleted{
    my $self = shift;
    return if !Utils::Feedbacks::authorized($self);
    select_objects($self,$DELETED_OBJECT_NAME,"/$OBJECT_NAMES/deleted");
};

sub select_objects{
    my ($self,$name,$path) = @_;
    return if !Utils::Feedbacks::authorized($self);

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
    return if !Utils::Feedbacks::authorized($self);

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
    return if !Utils::Feedbacks::authorized($self);

    my $id = $self->param('payload');
    if( $id ){
        my $db = Db->new($self);
        $db->change_name($DELETED_OBJECT_NAME, $id);
    } else {
        warn "$OBJECT_NAMES:delete:error $OBJECT_NAME id not defined!"; 
    }
    $self->redirect_to("/$OBJECT_NAMES/list");
};

sub del_final{
    my $self = shift;
    return if !Utils::Feedbacks::authorized($self);

    my $id = $self->param('payload');
    if( $id ){
        my $db = Db->new($self);
        $db->del($id);
    } else {
        warn "$OBJECT_NAMES:del_final:error $OBJECT_NAME id not defined!"; 
    }
    $self->redirect_to("/$OBJECT_NAMES/deleted");
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
