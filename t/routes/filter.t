use Mojo::Base -strict;

use Test::More;
use Test::Mojo::Session;

# Filter and paginator controller: set/reset/page/pagesize.

my $t = Test::Mojo::Session->new('Buh1');

my $path = '/accounts/list';

# --- GET filter/reset returns a redirect -------------------------------------

$t->get_ok("/filter/reset?path=$path")
  ->status_is(302, 'Filter reset redirects');

# --- GET filter/page sets current page and redirects -------------------------

$t->get_ok("/filter/page/2?path=$path")
  ->status_is(302, 'Filter page redirects');

# --- GET filter/pagesize sets page size and redirects ------------------------

$t->get_ok("/filter/pagesize/10?path=$path")
  ->status_is(302, 'Filter pagesize redirects');

# --- POST filter/set requires CSRF token -------------------------------------

$t->post_ok('/filter/set', form => { filter => 'test', path => $path })
  ->status_is(403, 'POST filter/set without CSRF token is rejected');

# --- POST filter/set with valid CSRF token sets filter and redirects ----------

$t->get_ok('/feedbacks/add');   # any GET to populate the session CSRF token
my $csrf = $t->tx->res->dom->at('input[name="csrf_token"]')->attr('value');

$t->post_ok('/filter/set', form => {
    csrf_token => $csrf,
    filter     => 'hello',
    path       => $path,
})->status_is(302, 'POST filter/set with CSRF redirects');

# After setting a filter, the target page still loads
$t->get_ok($path)->status_is(200, 'Filtered accounts/list still loads');

# --- Reset clears the filter -------------------------------------------------

$t->get_ok("/filter/reset?path=$path")
  ->status_is(302, 'Filter reset after setting a filter redirects');

done_testing();
