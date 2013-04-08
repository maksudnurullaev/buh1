package Utils::User; {

=encoding utf8

=head1 NAME

    Different utilites 

=cut

use 5.012000;
use strict;
use warnings;
use utf8;

our $LOGIN_FORMAT = '<a href="/initial/login">Login</a>'; 
our $LOGOUT_FORMAT = '<a href="/initial/logout">Logout</a>'; 

sub current{
    my $self = shift;
    if( $self ){
        return($self->session->{'user'} );
    }
    return;
};

sub bar{
    my $self = shift;
    my $result;
    $result = current($self) ? $LOGOUT_FORMAT : $LOGIN_FORMAT ;
    return (Mojo::ByteStream->new($result));
};

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
