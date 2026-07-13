use Mojo::Base -strict;

use Test::More;
use Test::Mojo::Session;
use Auth;
use Db;

# Buh1::Users::add / del / remove_company were reachable by anyone: no
# who_is() gate stood between an anonymous GET and creating a user,
# deleting one, or stripping a user's access to a company. Verify the
# added admin-only gate actually rejects unauthenticated requests without
# mutating anything, and that an admin can still perform these actions.

my $t  = Test::Mojo::Session->new('Buh1');
my $db = Db->new( $t->app );

my $TEST_PWD   = 'TestAdminPwd_routes_users!';
my $admin_file = $t->app->home->rel_file('config/admin.login');
my $saved_hash = do { open my $f, '<', $admin_file or die "Cannot read $admin_file: $!"; local $/; <$f> };
Auth::set_password( $t->app, 'admin', $TEST_PWD );

# --- Fixtures: throwaway user + company + link between them -----------------

my $user_id = $db->insert(
    {   object_name => 'user',
        id          => 'test-users-routes-users-t',
        email       => 'test-users-routes-t@example.com',
        password    => 'x',
    }
);
my $company_id = $db->insert(
    {   object_name => 'company',
        id          => 'test-company-routes-users-t',
        name        => 'Test company for users.t',
    }
);
$db->set_link( $company_id, $user_id );
$db->set_linked_value( 'access', $company_id, $user_id, 'writer' );

END {
    $db->del($user_id)    if $user_id;
    $db->del($company_id) if $company_id;
    if ( $saved_hash && open my $f, '>', $admin_file ) { print $f $saved_hash }
}

# --- Unauthenticated requests are rejected, nothing is mutated ---------------

$t->get_ok('/user/login');
my $csrf = $t->tx->res->dom->at('input[name="csrf_token"]')->attr('value');

$t->get_ok("/users/del/$user_id")
  ->status_is( 302, 'Unauthenticated GET /users/del is rejected' )
  ->header_like( Location => qr{/user/login}, 'Redirects to login' );

my $still_user = $db->get_objects( { id => [$user_id], name => ['user'] } );
ok( $still_user && $still_user->{$user_id},
    'User not renamed/deleted by unauthenticated request' );

$t->get_ok("/users/remove_company/$user_id?company=$company_id")
  ->status_is( 302, 'Unauthenticated GET /users/remove_company is rejected' )
  ->header_like( Location => qr{/user/login}, 'Redirects to login' );

ok( $db->is_linked( $company_id, $user_id ),
    'Company link untouched by unauthenticated request' );
ok( $db->get_linked_value( 'access', $company_id, $user_id ),
    'Access value untouched by unauthenticated request' );

$t->get_ok('/users/add')
  ->status_is( 302, 'Unauthenticated GET /users/add is rejected' )
  ->header_like( Location => qr{/user/login}, 'Redirects to login' );

$t->post_ok(
    '/users/add',
    form => {
        csrf_token => $csrf,
        email      => 'anonymous-created-routes-users-t@example.com',
        password1  => 'SomePassword123!',
        password2  => 'SomePassword123!',
    }
)->status_is( 302, 'Unauthenticated POST /users/add is rejected' )
  ->header_like( Location => qr{/user/login}, 'Redirects to login' );

my $rogue = $db->get_user('anonymous-created-routes-users-t@example.com');
ok( !$rogue, 'No user created by unauthenticated POST' );

# --- Login as admin ------------------------------------------------------------

$t->get_ok('/user/login');
$csrf = $t->tx->res->dom->at('input[name="csrf_token"]')->attr('value');
$t->post_ok(
    '/user/login',
    form => { csrf_token => $csrf, email => 'admin', password => $TEST_PWD }
)->status_is( 302, 'Admin login succeeds' );

# --- Admin can still perform these actions -----------------------------------

$t->get_ok('/users/add')->status_is( 200, 'Admin can GET /users/add' );

$t->get_ok("/users/remove_company/$user_id?company=$company_id")
  ->status_is( 302, 'Admin remove_company redirects to user edit page' )
  ->header_like( Location => qr{/users/edit/\Q$user_id\E},
    'Redirects to user edit page' );

ok( !$db->is_linked( $company_id, $user_id ), 'Company link removed by admin' );

$t->get_ok("/users/del/$user_id")
  ->status_is( 302, 'Admin del redirects to users list' )
  ->header_like( Location => qr{/users/list}, 'Redirects to users list' );

my $deleted = $db->get_objects( { id => [$user_id], name => ['deleted user'] } );
ok( $deleted && $deleted->{$user_id}, 'User renamed to deleted user by admin' );

done_testing();
