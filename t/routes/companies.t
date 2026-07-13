use Mojo::Base -strict;

use Test::More;
use Test::Mojo::Session;
use Auth;
use Db;
use Mojo::Util qw(url_unescape);

# Buh1::Companies had almost no auth checks: only edit() had one, and even
# that only required being logged in as *any* user, not an admin - despite
# the "Companies" nav link only ever being shown under the admin-only
# "Administration" section. Verify every action now requires a global admin,
# that unauthenticated/mutating requests are rejected without touching
# anything, and that an admin can still manage companies end to end.

my $t  = Test::Mojo::Session->new('Buh1');
my $db = Db->new( $t->app );

my $TEST_PWD   = 'TestAdminPwd_routes_companies!';
my $admin_file = $t->app->home->rel_file('config/admin.login');
my $saved_hash = do { open my $f, '<', $admin_file or die "Cannot read $admin_file: $!"; local $/; <$f> };
Auth::set_password( $t->app, 'admin', $TEST_PWD );

# --- Fixtures: a throwaway company + user, linked with reader access --------

my $company_id = $db->insert(
    {   object_name => 'company',
        id          => 'test-company-routes-companies-t',
        name        => 'Test company for companies.t',
    }
);
my $user_id = $db->insert(
    {   object_name => 'user',
        id          => 'test-user-routes-companies-t',
        email       => 'test-user-routes-companies-t@example.com',
        password    => 'x',
    }
);
$db->set_link( $company_id, $user_id );
$db->set_linked_value( 'access', $company_id, $user_id, 'reader' );

my @created_company_ids;

END {
    $db->del($company_id) if $company_id;
    $db->del($user_id)    if $user_id;
    $db->del($_) for @created_company_ids;
    if ( $saved_hash && open my $f, '>', $admin_file ) { print $f $saved_hash }
}

# --- Unauthenticated requests are rejected, nothing is mutated ---------------

$t->get_ok('/user/login');
my $csrf = $t->tx->res->dom->at('input[name="csrf_token"]')->attr('value');

$t->get_ok('/companies/add')
  ->status_is( 302, 'Unauthenticated GET /companies/add is rejected' )
  ->header_like( Location => qr{/user/login}, 'Redirects to login' );

$t->post_ok(
    '/companies/add',
    form => { csrf_token => $csrf, name => 'Rogue Company' }
)->status_is( 302, 'Unauthenticated POST /companies/add is rejected' )
  ->header_like( Location => qr{/user/login}, 'Redirects to login' );

$t->get_ok("/companies/edit/$company_id")
  ->status_is( 302, 'Unauthenticated GET /companies/edit is rejected' )
  ->header_like( Location => qr{/user/login}, 'Redirects to login' );

$t->post_ok(
    "/companies/edit/$company_id",
    form => { csrf_token => $csrf, name => 'Hacked Name' }
)->status_is( 302, 'Unauthenticated POST /companies/edit is rejected' )
  ->header_like( Location => qr{/user/login}, 'Redirects to login' );

my $unchanged = $db->get_objects( { id => [$company_id], name => ['company'] } );
ok( $unchanged->{$company_id} && $unchanged->{$company_id}{name} eq 'Test company for companies.t',
    'Company name unchanged after unauthenticated edit attempt' );

$t->get_ok("/companies/del/$company_id")
  ->status_is( 302, 'Unauthenticated GET /companies/del is rejected' )
  ->header_like( Location => qr{/user/login}, 'Redirects to login' );

my $still_company = $db->get_objects( { id => [$company_id], name => ['company'] } );
ok( $still_company->{$company_id}, 'Company not deleted by unauthenticated request' );

$t->get_ok("/companies/restore/$company_id")
  ->status_is( 302, 'Unauthenticated GET /companies/restore is rejected' )
  ->header_like( Location => qr{/user/login}, 'Redirects to login' );

$t->post_ok(
    "/companies/remove_user/$company_id?user=$user_id",
    form => { csrf_token => $csrf }
)->status_is( 302, 'Unauthenticated POST /companies/remove_user is rejected' )
  ->header_like( Location => qr{/user/login}, 'Redirects to login' );

ok( $db->is_linked( $company_id, $user_id ), 'User link untouched by unauthenticated request' );
ok( $db->get_linked_value( 'access', $company_id, $user_id ), 'Access value untouched by unauthenticated request' );

$t->post_ok(
    "/companies/change_access/$company_id?user_id=$user_id&user_access=admin",
    form => { csrf_token => $csrf }
)->status_is( 302, 'Unauthenticated POST /companies/change_access is rejected' )
  ->header_like( Location => qr{/user/login}, 'Redirects to login' );

is( $db->get_linked_value( 'access', $company_id, $user_id ), 'reader',
    'Access level unchanged by unauthenticated request' );

# --- Login as admin ------------------------------------------------------------

$t->get_ok('/user/login');
$csrf = $t->tx->res->dom->at('input[name="csrf_token"]')->attr('value');
$t->post_ok(
    '/user/login',
    form => { csrf_token => $csrf, email => 'admin', password => $TEST_PWD }
)->status_is( 302, 'Admin login succeeds' );

# --- Admin can still manage companies end to end -----------------------------

$t->get_ok('/companies/list')->status_is( 200, 'Admin can GET /companies/list' );
$t->get_ok('/companies/add')->status_is( 200, 'Admin can GET /companies/add' );

$t->post_ok(
    '/companies/add',
    form => { csrf_token => $csrf, name => 'Admin Created Company' }
)->status_is( 302, 'Admin can create a company' );
my ($new_id) = $t->tx->res->headers->location =~ m{/companies/edit/(.+)$};
$new_id = url_unescape($new_id) if $new_id;
ok( $new_id, 'Got the new company id from the redirect' );
push @created_company_ids, $new_id if $new_id;

$t->get_ok("/companies/edit/$company_id")
  ->status_is( 200, 'Admin can GET /companies/edit' );

$t->post_ok(
    "/companies/edit/$company_id",
    form => { csrf_token => $csrf, name => 'Renamed By Admin' }
)->status_is( 200, 'Admin can rename a company' );

my $renamed = $db->get_objects( { id => [$company_id] } );
is( $renamed->{$company_id}{name}, 'Renamed By Admin', 'Company renamed by admin' );

$t->post_ok(
    "/companies/change_access/$company_id?user_id=$user_id&user_access=writer",
    form => { csrf_token => $csrf }
)->status_is( 302, 'Admin can change a user\'s access level' );
is( $db->get_linked_value( 'access', $company_id, $user_id ), 'writer',
    'Access level updated by admin' );

$t->post_ok(
    "/companies/remove_user/$company_id?user=$user_id",
    form => { csrf_token => $csrf }
)->status_is( 302, 'Admin can remove a user from a company' );
ok( !$db->is_linked( $company_id, $user_id ), 'User link removed by admin' );

$t->post_ok(
    "/companies/add_user/$company_id?user=$user_id",
    form => { csrf_token => $csrf }
)->status_is( 302, 'Admin can add a user back to a company' );
ok( $db->is_linked( $company_id, $user_id ), 'User link re-created by admin' );

$t->get_ok("/companies/del/$company_id")
  ->status_is( 302, 'Admin del redirects to companies list' )
  ->header_like( Location => qr{/companies/list}, 'Redirects to companies list' );

my $deleted = $db->get_objects( { id => [$company_id], name => ['deleted company'] } );
ok( $deleted->{$company_id}, 'Company renamed to deleted company by admin' );

$t->get_ok('/companies/deleted')->status_is( 200, 'Admin can GET /companies/deleted' );

$t->get_ok("/companies/restore/$company_id")
  ->status_is( 302, 'Admin restore redirects to companies deleted list' )
  ->header_like( Location => qr{/companies/deleted}, 'Redirects to companies deleted list' );

my $restored = $db->get_objects( { id => [$company_id], name => ['company'] } );
ok( $restored->{$company_id}, 'Company restored by admin' );

done_testing();
