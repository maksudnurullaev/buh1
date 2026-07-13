use Mojo::Base -strict;

use Test::More;
use Test::Mojo::Session;
use Auth;
use Db;

# Buh1::Operations::edit must reject a POST from anyone who isn't a global
# editor. The template already hides the Save button for such users, but
# that's not enough on its own — a forged request straight to the controller
# must not be able to mutate the shared business-transaction reference data.

my $t  = Test::Mojo::Session->new('Buh1');
my $db = Db->new( $t->app );

my $TEST_PWD   = 'TestAdminPwd_routes_operations!';
my $admin_file = $t->app->home->rel_file('config/admin.login');
my $saved_hash = do { open my $f, '<', $admin_file or die "Cannot read $admin_file: $!"; local $/; <$f> };
Auth::set_password( $t->app, 'admin', $TEST_PWD );

# --- Fixture: a throwaway account + business transaction --------------------

my $account_id = $db->insert(
    {   object_name => 'account',
        id          => 'test-ops-account-routes-operations-t',
        rus         => 'Test account for operations.t',
    }
);
my $bt_id = $db->insert(
    {   object_name => 'business transaction',
        id          => 'test-ops-bt-routes-operations-t',
        number      => '999',
        rus         => 'Original description',
        debet       => '0100',
        credit      => '0200',
        account     => $account_id,
    }
);

END {
    $db->del($account_id) if $account_id;
    $db->del($bt_id)      if $bt_id;
    if ( $saved_hash && open my $f, '>', $admin_file ) { print $f $saved_hash }
}

my $edit_path = "/operations/edit/$account_id?bt=$bt_id";

# --- Unauthenticated POST must not mutate the record -------------------------

$t->get_ok('/user/login');
my $csrf = $t->tx->res->dom->at('input[name="csrf_token"]')->attr('value');

$t->post_ok(
    $edit_path,
    form => {
        csrf_token => $csrf,
        account    => $account_id,
        number     => '999',
        rus        => 'HACKED_BY_TEST',
        debet      => '0100',
        credit     => '0200',
    }
)->status_is( 302, 'Unauthenticated POST to operations/edit is rejected' )
  ->header_like( Location => qr{/user/login}, 'Redirects to login' );

my $unchanged = $db->get_objects( { id => [$bt_id] } );
is( $unchanged->{$bt_id}{rus}, 'Original description',
    'Record unchanged after unauthenticated POST' );

# --- Login as admin (editor-level access) ------------------------------------

$t->get_ok('/user/login');
$csrf = $t->tx->res->dom->at('input[name="csrf_token"]')->attr('value');
$t->post_ok(
    '/user/login',
    form => {
        csrf_token => $csrf,
        email      => 'admin',
        password   => $TEST_PWD,
    }
)->status_is( 302, 'Admin login succeeds' );

# --- Authenticated (editor) POST succeeds ------------------------------------

$t->get_ok($edit_path);
$csrf = $t->tx->res->dom->at('input[name="csrf_token"]')->attr('value');
ok( $csrf, 'CSRF token is present in the edit form once logged in as editor' );

$t->post_ok(
    $edit_path,
    form => {
        csrf_token => $csrf,
        account    => $account_id,
        number     => '999',
        rus        => 'Updated by admin',
        debet      => '0100',
        credit     => '0200',
    }
)->status_is( 200, 'Authenticated editor POST succeeds' );

my $changed = $db->get_objects( { id => [$bt_id] } );
is( $changed->{$bt_id}{rus}, 'Updated by admin',
    'Record updated after authenticated POST' );

done_testing();
