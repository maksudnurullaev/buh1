use Mojo::Base -strict;

use Test::More;
use Test::Mojo::Session;
use Auth;

# Authentication flow: login, logout, CSRF protection.
#
# We temporarily set the admin password to a known test value and restore the
# original hash in the END block so the running application is not affected.

my $t = Test::Mojo::Session->new('Buh1');

my $TEST_PWD    = 'TestAdminPwd_routes_auth!';
my $admin_file  = $t->app->home->rel_file('config/admin.login');
my $saved_hash  = do { open my $f, '<', $admin_file or die "Cannot read $admin_file: $!"; local $/; <$f> };
Auth::set_password($t->app, 'admin', $TEST_PWD);

END {
    if ($saved_hash && open my $f, '>', $admin_file) { print $f $saved_hash }
}

# --- CSRF protection ---------------------------------------------------------

# POST without any CSRF token must be rejected with 403
$t->post_ok('/user/login', form => { email => 'admin', password => $TEST_PWD })
  ->status_is(403, 'POST without CSRF token is forbidden');

# --- Login form --------------------------------------------------------------

$t->get_ok('/user/login')->status_is(200);
my $csrf = $t->tx->res->dom->at('input[name="csrf_token"]')->attr('value');
ok($csrf, 'CSRF token is present in the login form');

# --- Wrong credentials -------------------------------------------------------

$t->post_ok('/user/login', form => {
    csrf_token => $csrf,
    email      => 'admin',
    password   => 'wrong_password_xyz',
})->status_is(200, 'Wrong password re-renders the login form');

# --- Successful login --------------------------------------------------------

$t->get_ok('/user/login')->status_is(200);
$csrf = $t->tx->res->dom->at('input[name="csrf_token"]')->attr('value');

$t->post_ok('/user/login', form => {
    csrf_token => $csrf,
    email      => 'admin',
    password   => $TEST_PWD,
})->status_is(302, 'Valid credentials trigger a redirect');

# After login, home page is reachable without redirect
$t->get_ok('/')->status_is(200, 'Home page accessible after login');

# --- Logout ------------------------------------------------------------------

$t->get_ok('/user/logout')
  ->status_is(302, 'Logout redirects');

# After logout, a protected route redirects back to login
$t->get_ok('/users/list')
  ->status_is(302, 'Protected route redirects after logout')
  ->header_like(Location => qr{/user/login}, 'Redirect target is the login page');

done_testing();
