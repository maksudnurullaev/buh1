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

ok(Db::get_sqlite_file() =~ /\.db$/, "Test for db file");
ok(Db::get_db_connection(), "Get proper db connection (SQLITE)!");

# -= check for invalid hash =-
ok(!defined(Db::insert({})));
ok(!defined(Db::insert({object_name => "user"})));

# -= check for single insertrion =-
my $id_1 = Db::insert({
    object_name => "test object",
    field1      => "value1",
    field2      => "value2"});
ok($id_1);

# -= check for single select =-
my $hash_ref = Db::get_objects({id => [$id_1]});
my @ids = keys %{$hash_ref};
ok($id_1 eq $ids[0], "Test for equalness of ids!");
ok("value1" eq $hash_ref->{$id_1}{field1}, "Check for value #1");
ok("value2" eq $hash_ref->{$id_1}{field2}, "Check for value #2");

# -= check for single with many fields =-
my $many_fields_data = { object_name => "test object" };
for(my $i=1;$i<=100;$i++){
    $many_fields_data->{ "field$i" } = ("value" x $i); 
}
my $id_2 = Db::insert($many_fields_data);
ok($id_2, "Check for valid id!");

my $data = Db::get_objects({id => [$id_2]});
for(my $i=1;$i<=100;$i++){
    ok(length($data->{$id_2}{"field$i"}) == (5*$i), "Test for values!");
}

### -= FINISH =-
END{
    my $dbh = Db::get_db_connection();
    $dbh->do("DELETE FROM objects WHERE name = 'test object'");
};
done_testing();