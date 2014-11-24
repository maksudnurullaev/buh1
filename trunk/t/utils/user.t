use Test::More;
use Test::Mojo;
use Utils::User;

use_ok('Utils::User');
require_ok('Utils::User');

# Salted password
ok(!defined(Utils::User::current), "Non defined result with no parameters!");

### -=FINISH=-
done_testing();
