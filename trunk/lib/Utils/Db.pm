package Utils::Db; {

=encoding utf8

=head1 NAME

    Database utilites 

=cut

use 5.012000;
use strict;
use warnings;
use utf8;
use Data::Dumper;
use DbClient;

sub get_client_db{
    my $self = shift;
    if ( $self && $self->session('company id') ){
        return(new DbClient($self->session('company id')) );
    }
    return(undef);
};    

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

 M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
