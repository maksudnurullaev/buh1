use Test::More;
use t::Base;
use Data::Dumper;
use Utils;
use Utils::Cacher;
use Utils::Cacher;
use utf8;

my $test_mojo;
BEGIN { $t = t::Base::get_test_mojo_session(); }    

use_ok('Utils::Cacher');
require_ok('Utils::Cacher');

ok( !defined(Utils::User::current($self) ), "Non defined result with no parameters!");
$t->get_ok('/initial/welcome')->status_is(200);

### -=FINISH=-
done_testing();
