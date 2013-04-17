use Test::More;
use Test::Mojo;
use DBD::SQLite;
use Data::Dumper;
use Db;
use DBI;

BEGIN {
    use_ok('Db');
    require_ok('Db');
    ok(Db::initialize(), "Test for initialize script!");
    Db::set_production_mode(0);
};

# -= create some db objects for test =-
my ($name1, $name2, $name3) = ('test object 1', 'test object 2', 'test object 3');
my $data1 = { object_name => $name1, field1 => 'value1'};
my $data2 = { object_name => $name2, field2 => 'value2'};
my $data3 = { object_name => $name3, field3 => 'value3'};

my $id1 = Db::insert($data1);
my $id2 = Db::insert($data2);
my $id3 = Db::insert($data3);

ok($id1 && $id2 && $id3, 'Test for valid ids!');

# -= create single link between two objects =-
ok(Db::set_link($name1, $id1, $name2, $id2), "Set link #12");
ok(Db::set_link($name1, $id1, $name3, $id3), "Set link #13");

### -= FINISH =-
END{
    my $dbh = Db::get_db_connection();
    $dbh->do("DELETE FROM objects WHERE field LIKE 'test object%'");
};
done_testing();
