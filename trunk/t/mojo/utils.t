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

### -=FINISH=-
done_testing();
