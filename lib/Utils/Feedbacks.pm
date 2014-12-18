package Utils::Feedbacks; {

=encoding utf8

=head1 NAME

    Different utilites 

=cut

use 5.012000;
use strict;
use warnings;

sub authorized{
    my $self = shift;
    if( !$self->who_is_global('editor') ){
        $self->redirect_to('/user/login?warning=access');
        return(0);
    }
    return(1);
};

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
