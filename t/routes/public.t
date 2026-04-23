use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

# Public routes — accessible without any login

my $t = Test::Mojo->new('Buh1');

# Home page
$t->get_ok('/')->status_is(200);

# Login page — must include email, password and CSRF hidden field
$t->get_ok('/user/login')
  ->status_is(200)
  ->element_exists('input[name="email"]',      'Login form has email field')
  ->element_exists('input[name="password"]',   'Login form has password field')
  ->element_exists('input[name="csrf_token"]', 'Login form has CSRF token');

# Feedback submission form — open to everyone
$t->get_ok('/feedbacks/add')
  ->status_is(200)
  ->element_exists('input[name="csrf_token"]', 'Feedback form has CSRF token');

# Chart of accounts — public read
$t->get_ok('/accounts/list')->status_is(200);

# Business transactions — public read
$t->get_ok('/operations/list')->status_is(200);

# Guides — public read
$t->get_ok('/guides/page')->status_is(200);

# Calculations — public read
$t->get_ok('/calculations/page')->status_is(200);

done_testing();
