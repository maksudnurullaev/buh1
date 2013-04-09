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

our $LOGIN_FORMAT = '%s (<a href="/initial/login">%s</a>)'; 
our $LOGOUT_FORMAT = '%s (<a href="/initial/logout">%s</a>)'; 

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

sub bar{
    my $self = shift;
    my ($result, $name, $language) = (undef, current($self), Utils::Languages::current($self));
    if( $name ){
        $result = sprintf $LOGOUT_FORMAT, 
            $name, 
            ML::get_value('Logout', $language);
    } else {
        $result = sprintf $LOGIN_FORMAT, 
            ML::get_value('Guest', $language), 
            ML::get_value('Login', $language);
    }
    return (Mojo::ByteStream->new($result));
};

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
