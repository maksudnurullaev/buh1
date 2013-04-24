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

my $parameters = {id => ['2013.04.16 09:52:10 C792E7AC'],
                  field => ['name','description','user'],
                  name => ['company','_link_']};

my $sql_string = Db::format_sql_parameters($parameters);

ok($sql_string =~ /id =/, "Test for single parameter");
ok($sql_string =~ /name IN/, "Test for multiply parameters");
ok($sql_string =~ /field IN/, "Test for multiply parameters");


### -= FINISH =-
END{
    my $dbh = Db::get_db_connection();
    $dbh->do("DELETE FROM objects WHERE name = 'test object'");
};
done_testing();
