package Utils::Documents; {

=encoding utf8

=head1 NAME

    Documents utilites 

=cut

use 5.012000;
use strict;
use warnings;
use utf8;
use Data::Dumper;
use DbClient;
use Utils::Db;

sub attach{
    my ($self,$docid) = @_ ;
    return if !$docid ;
    my $db = Utils::Db::get_client_db($self);
    return if !$db;

    my $objects = $db->get_objects({id => [$docid], 
        field => ['document number', 'currency amount','details']});
    return(undef) if !$objects;
    my $document = $objects->{$docid};
    $self->session( docid => $docid );
    $self->session( document => $document );
};    

sub detach{
    my $self = shift;
    my $docid = $self->session->{docid};

    delete $self->session->{docid};
    delete $self->session->{document};
    return($docid);
};

# END OF PACKAGE
};

1

__END__

=head1 AUTHOR

 M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
