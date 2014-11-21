package t::database::Base; {

=encoding utf8

=head1 NAME

    Different utilites 

=cut

use strict;
use warnings;

use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use DbTest;
use File::Temp;

use_ok('DbTest');
require_ok('DbTest');

my $test_mojo = Test::Mojo->new('Buh1');
my $db_test_file 
             = File::Temp::tempnam( $test_mojo->app->home->rel_dir('t/database'), 'db_test_' ); 
our $test_db = DbTest->new($test_mojo);
$test_db->{'file'} = $db_test_file;

ok( $test_db->initialize(), 'Test for initialize script!');
ok( $test_db->is_valid, 'Check database' );

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
