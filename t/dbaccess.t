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

# -= check for invalid hash =-
ok(!defined(Db::insert({})));
ok(!defined(Db::insert({object_name => "user"})));
my $test_linked_value_name  = 'test access';
my $test_linked_value  = 'test value';

# -= check for single insertrion =-
my $id_1 = Db::insert({
    object_name => "test object",
    field1      => "value1",
    field2      => "value2"});
ok($id_1);
my $id_2 = Db::insert({
    object_name => "test object",
    field1      => "value22",
    field2      => "value222"});
ok($id_2);

# no linked value
my $linked_value1 = Db::get_linked_value($test_linked_value_name,$id_1,$id_2); 
ok(!$linked_value1);

# create and test linked value
ok(Db::set_linked_value($test_linked_value_name,$id_1,$id_2,$test_linked_value));
ok($test_linked_value eq Db::get_linked_value($test_linked_value_name,$id_1,$id_2));

# delete linked value
ok(Db::del_linked_value($test_linked_value_name,$id_1,$id_2));
ok(Db::get_linked_value($test_linked_value_name,$id_1,$id_2));

### -= FINISH =-
END{
    my $dbh = Db::get_db_connection();
    $dbh->do("DELETE FROM objects WHERE name = 'test object'");
    $dbh->do("DELETE FROM objects WHERE name = '$test_linked_value_name'");
};
done_testing();
