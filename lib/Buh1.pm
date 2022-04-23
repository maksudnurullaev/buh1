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
    ## Initial
    $r->get('/')->to( controller => 'initial', action => 'welcome' );
    $r->get('/initial/lang/:payload')
      ->to( controller => 'initial', action => 'lang' );

    ## Feedback
    $r->any('/feedbacks/add')->methods( 'GET', 'POST' )
      ->to( controller => 'feedbacks', action => 'add' );
    $r->get('/feedbacks/list')
      ->to( controller => 'feedbacks', action => 'list' );
    $r->get('/feedbacks/deleted')
      ->to( controller => 'feedbacks', action => 'deleted' );

    ## Users
    $r->any('/user/login')->methods( 'GET', 'POST' )
      ->to( controller => 'user', action => 'login' );
    $r->any('/user/password')->methods( 'GET', 'POST' )
      ->to( controller => 'user', action => 'password' );
    $r->get('/user/logout')->to( controller => 'user', action => 'logout' );
    $r->get('/users/list')->to( controller => 'users', action => 'list' );
    $r->get('/users/list/*payload')
      ->to( controller => 'users', action => 'list' );
    $r->any('/users/add')->methods( 'GET', 'POST' )
      ->to( controller => 'users', action => 'add' );
    $r->any('/users/edit/*payload')->methods( 'GET', 'POST' )
      ->to( controller => 'users', action => 'edit' );
    $r->any('/users/deleted')->methods( 'GET', 'POST' )
      ->to( controller => 'users', action => 'deleted' );
    $r->get('/users/del/*payload')
      ->to( controller => 'users', action => 'del' );

    # Accounts
    $r->get('/accounts/list')->to( controller => 'accounts', action => 'list' );
    $r->any('/accounts/edit/*payload')->methods( 'GET', 'POST' )
      ->to( controller => 'accounts', action => 'edit' );

    # Operations
    $r->get('/operations/list')
      ->to( controller => 'operations', action => 'list' );
    $r->any('/operations/edit/*payload')->methods( 'GET', 'POST' )
      ->to( controller => 'operations', action => 'edit' );
    $r->any('/operations/account/*payload')->methods( 'GET', 'POST' )
      ->to( controller => 'operations', action => 'account' );

    # Templates
    $r->get('/templates/list')
      ->to( controller => 'templates', action => 'list' );
    $r->any('/templates/files/*payload')->methods( 'GET', 'POST' )
      ->to( controller => 'templates', action => 'files' );
    $r->any('/templates/edit/*payload')->methods( 'GET', 'POST' )
      ->to( controller => 'templates', action => 'edit' );
    $r->any('/templates/move/*payload')->methods( 'GET', 'POST' )
      ->to( controller => 'templates', action => 'move' );

    # Guides
    $r->get('/guides/page')->to( controller => 'guides', action => 'page' );
    $r->get('/guides/view/*payload')
      ->to( controller => 'guides', action => 'view' );
    $r->any('/guides/add')->methods( 'GET', 'POST' )
      ->to( controller => 'guides', action => 'add' );
    $r->any('/guides/edit/*payload')->methods( 'GET', 'POST' )
      ->to( controller => 'guides', action => 'edit' );

    # Calculations
    $r->get('/calculations/page')
      ->to( controller => 'calculations', action => 'page' );
    $r->post('/calculations/edit')
      ->to( controller => 'calculations', action => 'edit' );
    $r->post('/calculations/add')
      ->to( controller => 'calculations', action => 'add' );
    $r->post('/calculations/update_fields')
      ->to( controller => 'calculations', action => 'update_fields' );
    $r->get('/calculations/delete')
      ->to( controller => 'calculations', action => 'delete' );

    # Companies
    $r->get('/companies/list')
      ->to( controller => 'companies', action => 'list' );
    $r->get('/companies/deleted')
      ->to( controller => 'companies', action => 'deleted' );
    $r->any('/companies/add')->methods( 'GET', 'POST' )
      ->to( controller => 'companies', action => 'add' );
    $r->any('/companies/edit/*payload')
      ->to( controller => 'companies', action => 'edit' );
    $r->post('/companies/add_user/*payload')
      ->to( controller => 'companies', action => 'add_user' );
    $r->post('/companies/remove_user/*payload')
      ->to( controller => 'companies', action => 'remove_user' );
    $r->get('/companies/del/*payload')
      ->to( controller => 'companies', action => 'del' );
    $r->get('/companies/restore/*payload')
      ->to( controller => 'companies', action => 'restore' );
    $r->post('/companies/change_access/*payload')
      ->to( controller => 'companies', action => 'change_access' );

    # Database administration
    $r->any('/database/page')->methods( 'GET', 'POST' )
      ->to( controller => 'database', action => 'page' );
    $r->any('/database/view/*payload')->methods( 'GET', 'POST' )
      ->to( controller => 'database', action => 'view' );

    # Filter
    $r->post('/filter/set')->to( controller => 'filter', action => 'set' );
    $r->get('/filter/reset')->to( controller => 'filter', action => 'reset' );
}

1;
