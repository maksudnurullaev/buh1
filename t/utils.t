use Test::More;
use Test::Mojo;
use Utils;
use List::MoreUtils qw/ uniq /;

use_ok('Utils');
require_ok('Utils');

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

### -=FINISH=-
done_testing();
