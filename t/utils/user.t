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
### -=FINISH=-
done_testing();
