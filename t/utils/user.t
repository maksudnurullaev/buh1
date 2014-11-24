use Test::More;
use t::Base;
use ML;
use Data::Dumper;
use Utils;
use utf8;
use Auth;

my $test_mojo;
BEGIN { $test_mojo     = t::Base::get_test_mojo_session(); }    

use_ok('Utils::User');
require_ok('Utils::User');

# Salted password
ok( !defined(Utils::User::current($self) ), "Non defined result with no parameters!");

### -=FINISH=-
done_testing();
