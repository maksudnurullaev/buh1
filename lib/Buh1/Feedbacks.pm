package Buh1::Feedbacks; {
use Mojo::Base 'Mojolicious::Controller';
use Auth;
use Utils;
use Utils::Filter;
use MIME::Base64 qw(encode_base64);

my $OBJECT_NAME         = 'feedback';
my $OBJECT_NAMES        = 'feedbacks';
my $DELETED_OBJECT_NAME = 'deleted feedbacks';

sub list{
    my $self = shift;
    return if !$self->who_is('global','editor');

    select_objects($self,$OBJECT_NAME,'');
};

sub deleted{
    my $self = shift;
    return if !$self->who_is('global','editor');

    select_objects($self,$DELETED_OBJECT_NAME,"/$OBJECT_NAMES/deleted");
};

sub select_objects{
    my ($self,$name,$path) = @_;
    return if !$self->who_is('global','editor');

    my $db = Db->new($self);
    my $filter    = Utils::Filter::get_filter($self);
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
    return if !$self->who_is('global','editor');

    my $id = $self->param('payload');
    if( $id ){
        my $db = Db->new($self);
        $db->change_name($OBJECT_NAME, $id);
    } else {
        $self->app->log->warn("$OBJECT_NAMES:restore:error $OBJECT_NAME id not defined!");
    }
    $self->redirect_to("/$OBJECT_NAMES/deleted");
};

sub _set_captcha {
    my $self = shift;
    return if Utils::User::current($self);    # skip for logged-in users
    my ( $a, $b ) = ( int( rand(9) ) + 1, int( rand(9) ) + 1 );
    $self->session->{captcha_a} = $a;
    $self->session->{captcha_b} = $b;

    # Encode the question as an SVG data URI so the numbers are never
    # visible as plain text in the HTML source.
    my $svg = qq{<svg xmlns="http://www.w3.org/2000/svg" width="130" height="34">}
            . qq{<rect width="130" height="34" fill="#f8f9fa" rx="4" stroke="#dee2e6"/>}
            . qq{<text x="10" y="24" font-family="monospace" font-size="20" fill="#212529">$a + $b = ?</text>}
            . qq{</svg>};
    $self->stash( captcha_img => 'data:image/svg+xml;base64,' . encode_base64( $svg, '' ) );
}

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

        # Captcha validation for guests
        my $expected  = ( $self->session->{captcha_a} || 0 )
                      + ( $self->session->{captcha_b} || 0 );
        my $submitted = Utils::trim( $self->param('captcha') ) // '';
        if ( !$expected || $submitted !~ /^\d+$/ || int($submitted) != $expected ) {
            $data->{error} = 1;
            $self->stash( captcha_class => 'error' );
        }
    }
    # Invalidate the used captcha so it cannot be replayed
    delete $self->session->{captcha_a};
    delete $self->session->{captcha_b};

    $data->{message} = Utils::trim $self->param('message');
    if( !$data->{message} ){
       $data->{error} = 1;
       $self->stash(message_class => "error");
    }

    return($data);
};

sub del{
    my $self = shift;
    return if !$self->who_is('global','editor');

    my $id = $self->param('payload');
    if( $id ){
        my $db = Db->new($self);
        $db->change_name($DELETED_OBJECT_NAME, $id);
    } else {
        $self->app->log->warn("$OBJECT_NAMES:delete:error $OBJECT_NAME id not defined!");
    }
    $self->redirect_to("/$OBJECT_NAMES/list");
};

sub del_final{
    my $self = shift;
    return if !$self->who_is('global','editor');

    my $id = $self->param('payload');
    if( $id ){
        my $db = Db->new($self);
        $db->del($id);
    } else {
        $self->app->log->warn("$OBJECT_NAMES:del_final:error $OBJECT_NAME id not defined!");
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
                $self->app->log->warn("$OBJECT_NAMES:add:error: could not add new one!");
            }
        } else {
            $self->stash(error => 1);
        }
    }
    # Generate a fresh captcha for every form render (GET and failed POST)
    _set_captcha($self) unless $self->stash('success');
    $self->render();
};

1;

};
