use Test::More;
use t::Base;
use ML;
use Data::Dumper;
use Utils;
use utf8;
use Auth;

use_ok('Auth');
require_ok('Auth');

my $test_mojo;
BEGIN { $test_mojo     = t::Base::get_test_mojo_session(); }    

# Salted password
ok(!defined(Auth::salted_password()), "Non defined result with no parameters!");
my $salt = Auth::salted_password('secret');
# diag($salt);
ok(defined($salt) && $salt, "Salt defined");
ok(Auth::salted_password('secret', $salt), "Password correct!");
ok(!Auth::salted_password('secret1', $salt), "Password incorrect!"); 

# Salted password for administrator
ok(Auth::get_admin_password($test_mojo), "Check password for administrator!");

### -=FINISH=-
done_testing();
