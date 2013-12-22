package Utils::Hr; {

=encoding utf8

=head1 NAME

    Database utilites 

=cut

use 5.012000;
use strict;
use warnings;
use utf8;
use Utils::Db;

my ($HR_DESRIPTOR_NAME,$HR_PERSON_NAME) = 
   ('hr descriptor',   'hr person') 

sub get_all_resources{
    my $self = shift;
    my $db = Utils::Db::get_client_db($self);
    if( !$db ){
        warn "Could not connect to client's db!";
        return(undef);
    }
    return({ id => { name => 'Hello from Moscow!' } });
};

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

 M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
