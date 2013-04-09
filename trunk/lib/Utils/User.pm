package Utils::User; {

=encoding utf8

=head1 NAME

    Different utilites 

=cut

use 5.012000;
use strict;
use warnings;
use utf8;
use ML;
use Utils::Languages;

sub current{
    my $self = shift;
    if( $self ){
        return($self->session->{'user'} );
    }
    return;
};

sub is_admin{
    my $self = shift;
    my $user = current($self);
    if( $user && $user =~ /^admin$/i ){
        return(1);
    }
    return(0);
};

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
