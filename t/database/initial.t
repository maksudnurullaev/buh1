use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use DbTest;

use_ok('DbTest');
require_ok('DbTest');

my $mojo = Test::Mojo->new('Buh1');
my $db   = DbTest->new($mojo);

ok($db->initialize(), "Test for initialize script!");
ok($db->get_db_connection(), "Get proper db connection (SQLITE)!");

### -= FINISH =-
END{
    unlink $db->{'file'};
};

done_testing();
