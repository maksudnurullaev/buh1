package Buh1;
use Mojo::Base 'Mojolicious';
use Auth;
use Db;
use Mojolicious::Plugin;

our $my_self;

# This method will run once at server start
sub startup {
    my $self = shift;
    $my_self = $self;

    $self->helper( cache => sub { state $cache = {} } );

    # Set up password for administrator
    Auth::get_admin_password($self)
      || die("Could not set up password for administrator!");

    # Initialize database
    my $db = Db->new($self);
    $db->initialize() || die("Could not set initialize database!");

    # setup plugins
    $self->plugin('HTMLTags');
    $self->plugin('RenderFile');
    $self->app->secrets( [ 'Nkjlkj344!!!#4jkj;l', 'Hl53gfsgd;-l=rtw45@#' ] );

    # production or development
    $self->app->mode('development');

    # $self->app->mode('production');
    # ... just for hypnotoad
    $self->app->config( hypnotoad => { listen => ['http://*:3000'] } );
    #
    my $r = $self->routes;

    # General route
    ## Initial controller part:
    $r->get('/')->to( controller => 'initial', action => 'welcome' );
    $r->get('/initial/lang/:payload')->to( controller => 'initial', action => 'lang' );

    ## Feedback controller part:
    $r->any('/feedbacks/add')->methods( 'GET', 'POST' )
      ->to( controller => 'feedbacks', action => 'add' );
    $r->get('/feedbacks/list')
      ->to( controller => 'feedbacks', action => 'list' );
    $r->get('/feedbacks/deleted')
      ->to( controller => 'feedbacks', action => 'deleted' );

    ## User controller part:
    $r->any('/user/login')->methods( 'GET', 'POST' )
      ->to( controller => 'user', action => 'login' );
    $r->any('/user/password')->methods( 'GET', 'POST' )
      ->to( controller => 'user', action => 'password' );
    $r->get('/user/logout')
      ->to( controller => 'user', action => 'logout' );
    $r->get('/users/list')
      ->to( controller => 'users', action => 'list' );
    $r->get('/users/list/*payload')
      ->to( controller => 'users', action => 'list' );
    $r->any('/users/add')->methods( 'GET', 'POST' )
      ->to( controller => 'users', action => 'add' );
    $r->any('/users/edit/*payload')->methods( 'GET', 'POST' )
      ->to( controller => 'users', action => 'edit' );
    $r->any('/users/deleted')->methods( 'GET', 'POST' )
      ->to( controller => 'users', action => 'deleted' );

    # Accounts
    $r->get('/accounts/list')
      ->to( controller => 'accounts', action => 'list' );

}

1;
