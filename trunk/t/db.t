use Test::More;
use Test::Mojo;
use DBD::SQLite;
use Db;
use DBI;

use_ok('Db');
require_ok('Db');

ok(Db::get_sqlite_file() =~ /\.db$/, "Test for db file");
ok(Db::get_db_connection(), "Get proper db connection (SQLITE)!");

# -= check for invalid hash =-
ok(!defined(Db::insert_object({})));
ok(!defined(Db::insert_object({object_name => "user"})));

# -= check for single insertrion =-
my $id_1 = Db::insert_object({
    object_name => "test object",
    field1 => "value1",
    field2 => "value2"});
ok($id_1);

# -= check for single select =-
my $hash_ref = Db::select_object($id_1);
my @ids = keys %{$hash_ref};
ok($id_1 eq $ids[0]);

### -=FINISH=-
END{
    my $dbh = Db::get_db_connection();
    $dbh->do("DELETE FROM objects WHERE name = 'test object'");
};
done_testing();
