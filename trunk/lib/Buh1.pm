package Buh1;
use Mojo::Base 'Mojolicious';
use ML;
use Cwd;

# This method will run once at server start
sub startup {
  my $self = shift;

  # Documentation browser under "/perldoc"
  $self->plugin('PODRenderer');
  $self->plugin('ML');
  $self->app->secret('Nkjlkj344!!!#4jkj;l');
  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('initial#welcome');
  $r->get("/lang/:lang")->to(controller => 'initial', action => 'locale');

}

1;
