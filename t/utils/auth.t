use Test::More;
use Test::Mojo;
use Auth;

use_ok('Auth');
require_ok('Auth');

# Salted password
ok(!defined(Auth::salted_password), "Non defined result with no parameters!");
my $salt = Auth::salted_password('secret');
ok(defined($salt) && $salt, "Salt defined!");
ok(Auth::salted_password('secret', $salt), "Password correct!");
ok(!Auth::salted_password('secret1', $salt), "Password incorrect!"); 

# Salted password for administrator
ok(Auth::get_admin_password(), "Check password for administrator!");

### -=FINISH=-
done_testing();
