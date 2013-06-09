package Utils::User; {

=encoding utf8

=head1 NAME

    Different utilites 

=cut

use 5.012000;
use strict;
use warnings;
use utf8;
use Data::Dumper;
use ML;
use Utils::Languages;

sub current{
    my $self = shift;
    if( $self ){
        return($self->session->{'email'} );
    }
    return;
};

sub is_admin{
    my $self = shift;
    my $email = current($self);
    if( $email && $email =~ /^admin$/i ){
        return(1);
    }
    return(0);
};

sub is_editor{
    my $self = shift;

    my $email = current($self);
    warn $email;
    if( $email ){
        my $user = Db::get_user($email);
        warn Dumper $user;
        warn $user->{extended_right} if 
		exists($user->{extended_right})
             && $user->{extended_right} =~ /editor/i ;	
        return(1) if $user 
             && exists($user->{extended_right})
             && $user->{extended_right} =~ /editor/i ;
    }

    return(1) if is_admin($self);
    return(0);
};

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
