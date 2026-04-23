use Mojo::Base -strict;

use Test::More;
use Test::Mojo::Session;
use Auth;
use MIME::Base64 qw(decode_base64);

# Feedback controller: public submission, admin-only list.

my $t = Test::Mojo::Session->new('Buh1');

my $TEST_PWD   = 'TestAdminPwd_routes_feedbacks!';
my $admin_file = $t->app->home->rel_file('config/admin.login');
my $saved_hash = do { open my $f, '<', $admin_file or die "Cannot read $admin_file: $!"; local $/; <$f> };
Auth::set_password($t->app, 'admin', $TEST_PWD);

END {
    if ($saved_hash && open my $f, '>', $admin_file) { print $f $saved_hash }
}

# --- Feedback form is public -------------------------------------------------

$t->get_ok('/feedbacks/add')
  ->status_is(200, 'Feedback form is publicly accessible')
  ->element_exists('textarea[name="message"]', 'Form has a message textarea')
  ->element_exists('input[name="csrf_token"]', 'Form has a CSRF token');

# --- POST without CSRF is rejected -------------------------------------------

$t->post_ok('/feedbacks/add', form => { message => 'test' })
  ->status_is(403, 'POST without CSRF token is forbidden');

# Helper: decode the base64 SVG captcha image and compute the expected answer.
sub captcha_answer {
    my $img = shift->tx->res->dom->at('img.captcha-img') or return undef;
    my ($b64) = ( $img->attr('src') // '' ) =~ /base64,(.+)$/;
    my $svg = decode_base64( $b64 // '' );
    my ($a, $b) = $svg =~ /(\d+)\s*\+\s*(\d+)/;
    return defined $a ? $a + $b : undef;
}

# --- POST with wrong captcha shows error -------------------------------------

$t->get_ok('/feedbacks/add');
my $csrf = $t->tx->res->dom->at('input[name="csrf_token"]')->attr('value');

$t->post_ok('/feedbacks/add', form => {
    csrf_token => $csrf,
    message    => 'Test message',
    captcha    => 9999,            # deliberately wrong
})->status_is(200, 'Wrong captcha re-renders the form');

$t->element_exists('form', 'Form is re-rendered on captcha error');

# --- POST with empty message shows error -------------------------------------

$t->get_ok('/feedbacks/add');
$csrf = $t->tx->res->dom->at('input[name="csrf_token"]')->attr('value');
my $answer = captcha_answer($t);

$t->post_ok('/feedbacks/add', form => {
    csrf_token => $csrf,
    message    => '',
    captcha    => $answer,
})->status_is(200, 'Empty message re-renders the form');

$t->element_exists('form', 'Form is re-rendered on validation error');

# --- Valid feedback submission succeeds --------------------------------------

$t->get_ok('/feedbacks/add');
$csrf   = $t->tx->res->dom->at('input[name="csrf_token"]')->attr('value');
$answer = captcha_answer($t);

$t->post_ok('/feedbacks/add', form => {
    csrf_token => $csrf,
    message    => 'Test feedback from automated test suite',
    user       => 'test-runner',
    captcha    => $answer,
})->status_is(200, 'Valid feedback submission returns 200');

# success=1 stash renders the success alert
$t->element_exists('.alert-success', 'Success alert shown after submission');

# --- Feedback list requires editor rights ------------------------------------

# Not logged in — redirect to login
$t->get_ok('/feedbacks/list')
  ->status_is(302, 'Feedback list requires editor rights')
  ->header_like(Location => qr{/user/login}, 'Redirects to login');

# Login as admin (admin is a superset of editor)
$t->get_ok('/user/login');
$csrf = $t->tx->res->dom->at('input[name="csrf_token"]')->attr('value');
$t->post_ok('/user/login', form => {
    csrf_token => $csrf,
    email      => 'admin',
    password   => $TEST_PWD,
})->status_is(302, 'Admin login succeeds');

$t->get_ok('/feedbacks/list')
  ->status_is(200, 'Admin can view feedback list');

done_testing();
