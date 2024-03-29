use Test::More;
use Tests::Base;
use Data::Dumper;
use Utils;
use Utils::Cacher;
use utf8;

my $test_mojo;
BEGIN { $t = Tests::Base::get_test_mojo_session(); }    

use_ok('Utils::Cacher');
require_ok('Utils::Cacher');

$t->get_ok('/')->status_is(200);

### -=FINISH=-
done_testing();
