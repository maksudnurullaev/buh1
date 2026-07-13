use Mojo::Base -strict;

use Test::More;
use Test::Mojo::Session;
use Auth;

# Access control: unauthenticated users are redirected; admin can access all.
#
# Note: /companies/add, /companies/edit/*, /companies/del/*, /companies/restore/*,
# /companies/add_user/*, /companies/remove_user/*, /companies/change_access/* are
# covered separately in companies.t, since they need a company fixture to
# exercise meaningfully.

my $t = Test::Mojo::Session->new('Buh1');

my $TEST_PWD   = 'TestAdminPwd_routes_protected!';
my $admin_file = $t->app->home->rel_file('config/admin.login');
my $saved_hash = do { open my $f, '<', $admin_file or die "Cannot read $admin_file: $!"; local $/; <$f> };
Auth::set_password($t->app, 'admin', $TEST_PWD);

END {
    if ($saved_hash && open my $f, '>', $admin_file) { print $f $saved_hash }
}

# --- Unauthenticated access redirects to login -------------------------------

my @admin_routes = qw(
    /users/list
    /users/deleted
    /database/adb
    /database/counts
    /companies/list
    /companies/deleted
);

my @editor_routes = qw(
    /feedbacks/list
    /feedbacks/deleted
);

for my $route (@admin_routes, @editor_routes) {
    $t->get_ok($route)
      ->status_is(302, "GET $route unauthenticated gives 302")
      ->header_like(Location => qr{/user/login}, "$route redirects to login");
}

# Password change page also requires login
$t->get_ok('/user/password')
  ->status_is(302, 'Password page requires login')
  ->header_like(Location => qr{/user/login}, 'Redirects to login');

# --- Login as admin ----------------------------------------------------------

$t->get_ok('/user/login');
my $csrf = $t->tx->res->dom->at('input[name="csrf_token"]')->attr('value');

$t->post_ok('/user/login', form => {
    csrf_token => $csrf,
    email      => 'admin',
    password   => $TEST_PWD,
})->status_is(302, 'Admin login succeeds');

# --- Admin can reach all protected routes ------------------------------------

for my $route (@admin_routes) {
    $t->get_ok($route)->status_is(200, "Admin can GET $route");
}

for my $route (@editor_routes) {
    $t->get_ok($route)->status_is(200, "Admin can GET $route");
}

# Admin can also reach user management pages
$t->get_ok('/users/add')->status_is(200, 'Admin can GET /users/add');

done_testing();
