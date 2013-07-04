use Test::More;
use Test::Mojo;
use DBD::SQLite;
use Data::Dumper;
use Db;
use DBI;

my $db = Db->new();
BEGIN {
    use_ok('Db');
    require_ok('Db');
    my $db = Db->new();
    ok($db->initialize(), "Test for initialize script!");
    $db->set_production_mode(0);
};

# -= test for some non-existed link =-
ok(!$db->exists_link('invalid id #1', 'invalid id #2'), "test non-existed link");

# -= create some db objects for test =-
my ($name1, $name2) = ('test object 1', 'test objects 2 3');
my $data1 = { object_name => $name1, field1 => 'value1'};
my $data2 = { object_name => $name2, field2 => 'value2'};
my $data3 = { object_name => $name2, field3 => 'value3'};

my $id1 = $db->insert($data1);
my $id2 = $db->insert($data2);
my $id3 = $db->insert($data3);

ok($id1 && $id2 && $id3, 'Test for valid ids!');

# -= create linkis between three objects =-
ok($db->set_link($name1, $id1, $name2, $id2), "Set link #12");
ok($db->exists_link($id1,$id2), "Test for link existance #12");
ok($db->set_link($name1, $id1, $name2, $id3), "Set link #13");
ok($db->exists_link($id1,$id3), "Test for link existance #13");

# -= get links =-
my $result = $db->get_links($id1,$name2);
ok(exists($result->{$id2}), "Test for existance of #12");
ok(exists($result->{$id3}), "Test for existance of #13");
ok(scalar(keys %{$result}) == 2, "Test for result count");

# -= delete link =-
ok($db->del_link($id1,$id2), "Delete link for #12");
$result = $db->get_links($id1,$name2);
ok(!exists($result->{$id2}), "Test NOT for existance of #12");
ok(exists($result->{$id3}), "Test for existance of #13");
ok(scalar(keys %{$result}) == 1, "Test for result count");

$result = $db->get_links($id2,$name1);
ok(!exists($result->{$id1}), "Test NOT for existance of #1 for #12");

### -= FINISH =-
END{
    my $dbh = $db->get_db_connection();
    $dbh->do("DELETE FROM objects WHERE name='_link_' AND field LIKE 'test%' ; ");
    $dbh->do("DELETE FROM objects WHERE name LIKE 'test object%' ; ");
};
done_testing();
