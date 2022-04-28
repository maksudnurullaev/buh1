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
    $r->any('/calculations/page')->methods( 'GET', 'POST' )
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
    $r->get('/filter/page/#page')
      ->to( controller => 'filter', action => 'page' );
    $r->get('/filter/pagesize/#pagesize')
      ->to( controller => 'filter', action => 'pagesize' );

    ### Companies

    # Desktop
    $r->get('/desktop/company')
      ->to( controller => 'desktop', action => 'company' );
    $r->get('/desktop/company/*payload')
      ->to( controller => 'desktop', action => 'company' );

    # Documents
    $r->get('/documents/list')
      ->to( controller => 'documents', action => 'list' );
    $r->any('/documents/add')->methods( 'GET', 'POST' )
      ->to( controller => 'documents', action => 'add' );
    $r->any('/documents/update/*account')->methods( 'GET', 'POST' )
      ->to( controller => 'documents', action => 'update' );
    $r->any('/documents/update/')->methods( 'GET', 'POST' )
      ->to( controller => 'documents', action => 'update' );
    $r->get('/documents/print/*account')
      ->to( controller => 'documents', action => 'print' );
    $r->post('/documents/update_document_header/*account')
      ->to( controller => 'documents', action => 'update_document_header' );
    $r->get('/documents/cancel_update_document_header/*account')->to(
        controller => 'documents',
        action     => 'cancel_update_document_header'
    );

    # TBalance
    $r->any('/tbalance/page')->methods( 'GET', 'POST' )
      ->to( controller => 'tbalance', action => 'page' );
    $r->get('/tbalance/page/*account')
      ->to( controller => 'tbalance', action => 'page' );

    # Catalog
    $r->get('/catalog/list')->to( controller => 'catalog', action => 'list' );
    $r->any('/catalog/add')->methods( 'GET', 'POST' )
      ->to( controller => 'catalog', action => 'add' );
    $r->any('/catalog/edit/*payload')->methods( 'GET', 'POST' )
      ->to( controller => 'catalog', action => 'edit' );
    $r->any('/catalog/files/*payload')->methods( 'GET', 'POST' )
      ->to( controller => 'catalog', action => 'files' );

    # Files
    $r->post('/files/add/*payload')
      ->to( controller => 'files', action => 'add' );
    $r->any('/catalog/calculations/*payload')
      ->to( controller => 'catalog', action => 'calculations' );

    # Wirehouse
    $r->get('/warehouse/list')
      ->to( controller => 'warehouse', action => 'list' );
    $r->any('/warehouse/add')->methods( 'GET', 'POST' )
      ->to( controller => 'warehouse', action => 'add' );
    $r->any('/warehouse/edit/*payload')->methods( 'GET', 'POST' )
      ->to( controller => 'warehouse', action => 'edit' );
    $r->post('/warehouse/add_tag/*payload')
      ->to( controller => 'warehouse', action => 'add_tag' );
    $r->post('/warehouse/update_tag/*payload')
      ->to( controller => 'warehouse', action => 'update_tag' );
    $r->post('/warehouse/update_counting_field/*payload')
      ->to( controller => 'warehouse', action => 'update_counting_field' );
    $r->any('/warehouse/remains/*payload')->methods( 'GET', 'POST' )
      ->to( controller => 'warehouse', action => 'remains' );
    $r->get('/warehouse/remains_all')
      ->to( controller => 'warehouse', action => 'remains_all' );
    $r->get('/warehouse/files/*payload')
      ->to( controller => 'warehouse', action => 'files' );
    $r->get('/warehouse/calculations/*payload')
      ->to( controller => 'warehouse', action => 'calculations' );
    $r->post('/warehouse/export')
      ->to( controller => 'warehouse', action => 'export' );
    $r->post('/warehouse/export_remains/*payload')
      ->to( controller => 'warehouse', action => 'export_remains' );
    $r->get('/warehouse/del_tag/*payload')
      ->to( controller => 'warehouse', action => 'del_tag' );

}

1;
