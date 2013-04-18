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

# -= test for some non-existed link =-
ok(!Db::exists_link('invalid id #1', 'invalid id #2'), "test non-existed link");

# -= create some db objects for test =-
my ($name1, $name2) = ('test object 1', 'test objects 2 3');
my $data1 = { object_name => $name1, field1 => 'value1'};
my $data2 = { object_name => $name2, field2 => 'value2'};
my $data3 = { object_name => $name2, field3 => 'value3'};

my $id1 = Db::insert($data1);
my $id2 = Db::insert($data2);
my $id3 = Db::insert($data3);

ok($id1 && $id2 && $id3, 'Test for valid ids!');

# -= create linkis between three objects =-
ok(Db::set_link($name1, $id1, $name2, $id2), "Set link #12");
ok(Db::exists_link($id1,$id2), "Test for link existance #12");
ok(Db::set_link($name1, $id1, $name2, $id3), "Set link #13");
ok(Db::exists_link($id1,$id3), "Test for link existance #13");

# -= get links =-
my $result = Db::get_link($id1,$name2);
ok(exists($result->{$id2}), "Test for existance of #12");
ok(exists($result->{$id3}), "Test for existance of #13");
ok(scalar(keys %{$result}) == 2, "Test for result count");

# -= delete link =-
ok(Db::del_link($id2), "Delete link for #12");
$result = Db::get_link($id1,$name2);
ok(!exists($result->{$id2}), "Test NOT for existance of #12");
ok(exists($result->{$id3}), "Test for existance of #13");
ok(scalar(keys %{$result}) == 1, "Test for result count");

### -= FINISH =-
END{
    my $dbh = Db::get_db_connection();
    $dbh->do("DELETE FROM objects WHERE name='_link_' AND field LIKE 'test%' ; ");
    $dbh->do("DELETE FROM objects WHERE name LIKE 'test object%' ; ");
};
done_testing();
