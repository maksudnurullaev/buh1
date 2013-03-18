use Test::More;
use Test::Mojo;
use Utils;
use List::MoreUtils qw/ uniq /;

use_ok('Utils');
require_ok('Utils');

my @uuids;
for(my $count = 0; $count < 1000; $count++){
    push @uuids, Utils::get_date_uuid();
}
my @uuids_unique = uniq @uuids;
ok(scalar(@uuids_unique) == scalar(@uuids), "Test for uniqueness of each ID");

### -=FINISH=-
done_testing();
