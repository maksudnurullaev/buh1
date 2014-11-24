package t::database::Base; {

=encoding utf8

=head1 NAME

    Database test utilites 

=cut

use strict;
use warnings;

use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use t::Base;

use DbTest;
use File::Temp;

use_ok('DbTest');
require_ok('DbTest');

sub get_test_db{
    my $test_mojo = t::Base::get_test_mojo();
    my $test_db   = DbTest->new( $test_mojo );
    $test_db->{'file'} 
                  = File::Temp::tempnam( $test_mojo->app->home->rel_dir('t/database'), 'db_test_' ); 
    ok( $test_db->initialize(), 'Test for initialize script!' );
    ok( $test_db->is_valid, 'Check database' );
    return( $test_db );
}

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
