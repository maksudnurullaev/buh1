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
	my $db_client = new DbClient($self->session('company id'));
        return($db_client) if $db_client->is_valid ;
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
