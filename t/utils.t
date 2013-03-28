use Test::More;
use Test::Mojo;
use Utils;
use List::MoreUtils qw/ uniq /;

use_ok('Utils');
require_ok('Utils');

# trim tests
ok(!defined(Utils::trim()), "Check for undef parameter for trim!");
ok(!defined(Utils::trim("")), "Check for empty string parameter for trim!");
ok(defined(Utils::trim("  1  ")), "Check for non empty string!");
ok(length(Utils::trim("  1  ")) == 1, "Check for string length!");

# UUID tests
my @uuids;
for(my $count = 0; $count < 1000; $count++){
    push @uuids, Utils::get_date_uuid();
}
my @uuids_unique = uniq @uuids;
ok(scalar(@uuids_unique) == scalar(@uuids), "Test for uniqueness of each ID");

# Root path tests
ok(Utils::get_root_path(), "Non empty root path");
ok(Utils::get_root_path("some_path") =~ /some_path$/, "Create folder path from root location");
ok(Utils::get_root_path("some_path","some_file") =~ /some_path\/some_file$/, "Create folder/file path from root location");

# Salted password
ok(!defined(Utils::salted_password), "Non defined result with no parameters!");
my $salt = Utils::salted_password('secret');
ok(defined($salt), "Salt defined!");
ok(Utils::salted_password('secret', $salt), "Password correct!");
ok(!Utils::salted_password('secret1', $salt), "Password incorrect!"); 

### -=FINISH=-
done_testing();
