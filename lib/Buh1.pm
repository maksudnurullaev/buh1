package Buh1;
use Mojo::Base 'Mojolicious';
use ML;
use Auth;
use Db;
use Cwd;

BEGIN {
  # Set up password for administrator
  Auth::get_admin_password() || die("Could not set up password for administrator!");
  # Initialize database
  Db::initialize() || die("Could not set initialize database!");
};


# This method will run once at server start
sub startup {
  my $self = shift;

  # Documentation browser under "/perldoc"
  $self->plugin('PODRenderer');
  $self->plugin('HTMLTags');
  $self->app->secret('Nkjlkj344!!!#4jkj;l');

  my $r = $self->routes;
  # General route
  $r->route('/:controller/:action/*id')->via('GET','POST')
    ->to(controller => 'initial', action => 'welcome', id => undef);
};

1;
