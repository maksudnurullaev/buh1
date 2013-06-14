use Test::More;
use Test::Mojo;
use DBD::SQLite;
use Data::Dumper;
use DbClient;
use DBI;

BEGIN {
    use_ok('DbClient');
    require_ok('DbClient');
};

my $db_client = new DbClient('test');
ok($db_client->is_valid(),        'Stage #1 - Client database porperly initialized!!');

### -= FINISH =-
END{
  unlink $db_client->get_db_path ;
};
done_testing();
