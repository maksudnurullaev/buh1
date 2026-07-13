use Mojo::Base -strict;

use Test::More;
use Test::Mojo::Session;
use Auth;
use Db;
use Utils::Files;
use File::Path qw(remove_tree);

# Buh1::Files had no auth checks anywhere in the controller or in
# Utils::Files.pm: download/update_desc/update_file/add/delete were all
# reachable by anyone. Files are stored per-company under
# db/clients/<company_id>/<pid>/, so the same who_is('local', ...) gate
# Catalog.pm/Warehouse.pm already use is the right fit. Verify
# unauthenticated requests are rejected and nothing is written to disk,
# and that an authenticated writer can still upload/download/update/
# delete a file.

my $t  = Test::Mojo::Session->new('Buh1');
my $db = Db->new( $t->app );

my $TEST_PWD   = 'TestAdminPwd_routes_files!';
my $admin_file = $t->app->home->rel_file('config/admin.login');
my $saved_hash = do { open my $f, '<', $admin_file or die "Cannot read $admin_file: $!"; local $/; <$f> };
Auth::set_password( $t->app, 'admin', $TEST_PWD );

# --- Fixture: a throwaway company with admin granted writer access ----------
# (ids are alnum-only: Utils::Files::get_path strips anything else, so a
# hyphenated id wouldn't match the resulting directory name)

my $company_id = $db->insert(
    {   object_name => 'company',
        id          => 'testcompanyroutesfilest',
        name        => 'Test company for files.t',
    }
);
$db->set_linked_value( 'access', $company_id, 'admin', 'writer' );

my $pid        = 'testpidroutesfilest';
my $client_dir = $t->app->home->rel_file("db/clients/$company_id");

END {
    $db->del($company_id) if $company_id;
    remove_tree($client_dir) if -d $client_dir;
    unlink( $t->app->home->rel_file("db/clients/$company_id.db") );
    if ( $saved_hash && open my $f, '>', $admin_file ) { print $f $saved_hash }
}

# --- Unauthenticated requests are rejected, nothing is mutated ---------------

$t->get_ok('/user/login');
my $csrf = $t->tx->res->dom->at('input[name="csrf_token"]')->attr('value');

$t->get_ok("/files/download/$pid?fileid=whatever&prefix=catalog")
  ->status_is( 302, 'Unauthenticated GET /files/download is rejected' )
  ->header_like( Location => qr{/user/login}, 'Redirects to login' );

$t->post_ok(
    "/files/add/$pid?prefix=catalog",
    form => {
        csrf_token   => $csrf,
        pid          => $pid,
        path         => '/catalog/files',
        'file.field' => { content => 'hello world', filename => 'note.txt' },
    }
)->status_is( 302, 'Unauthenticated POST /files/add is rejected' )
  ->header_like( Location => qr{/user/login}, 'Redirects to login' );

ok( !-d $client_dir, 'No file was written to disk by unauthenticated request' );

$t->post_ok(
    '/files/update_desc',
    form => {
        csrf_token  => $csrf,
        pid         => $pid,
        prefix      => 'catalog',
        path        => '/catalog/files',
        fileid      => 'whatever',
        'file.desc' => 'hacked description',
    }
)->status_is( 302, 'Unauthenticated POST /files/update_desc is rejected' )
  ->header_like( Location => qr{/user/login}, 'Redirects to login' );

$t->get_ok("/files/delete?prefix=catalog&pid=$pid&fileid=whatever&path=/catalog/files")
  ->status_is( 302, 'Unauthenticated GET /files/delete is rejected' )
  ->header_like( Location => qr{/user/login}, 'Redirects to login' );

# --- Login as admin and deploy the fixture company ---------------------------

$t->get_ok('/user/login');
$csrf = $t->tx->res->dom->at('input[name="csrf_token"]')->attr('value');
$t->post_ok(
    '/user/login',
    form => { csrf_token => $csrf, email => 'admin', password => $TEST_PWD }
)->status_is( 302, 'Admin login succeeds' );

$t->get_ok("/desktop/company/$company_id")
  ->status_is( 200, 'Deploying the fixture company succeeds' );

# --- Authenticated writer can upload, download, update, delete --------------

$t->post_ok(
    "/files/add/$pid?prefix=catalog",
    form => {
        csrf_token   => $csrf,
        pid          => $pid,
        path         => '/catalog/files',
        'file.field' => { content => 'hello world', filename => 'note.txt' },
    }
)->status_is( 302, 'Authenticated writer can upload a file' );

my @uploaded = glob("$client_dir/$pid/*.name");
is( scalar(@uploaded), 1, 'Exactly one file was uploaded' );
my ($fileid) = $uploaded[0] =~ m{/([^/]+)\.name$};
ok( $fileid, 'Got the generated file id' );

$t->get_ok("/files/download/$pid?fileid=$fileid&prefix=catalog")
  ->status_is( 200, 'Authenticated writer can download the file' );

$t->post_ok(
    '/files/update_desc',
    form => {
        csrf_token  => $csrf,
        pid         => $pid,
        prefix      => 'catalog',
        path        => '/catalog/files',
        fileid      => $fileid,
        'file.desc' => 'updated description',
    }
)->status_is( 302, 'Authenticated writer can update the description' );

is( Utils::Files::get_file_content("$client_dir/$pid/$fileid.desc"),
    'updated description', 'Description was updated on disk' );

$t->get_ok("/files/delete?prefix=catalog&pid=$pid&fileid=$fileid&path=/catalog/files")
  ->status_is( 302, 'Authenticated writer can delete the file' );

ok( !-e "$client_dir/$pid/$fileid", 'File removed from disk' );

done_testing();
