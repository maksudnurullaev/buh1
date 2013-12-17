package Buh1::Hr; {

=encoding utf8

=head1 NAME

    Accounts controller

=cut

use Mojo::Base 'Mojolicious::Controller';
use Utils::Hr ;

sub add{
    my $self = shift;

    my $method = $self->req->method;
    if ( $method =~ /POST/ ){
    } else {
	}
	$self->redirect_to('hr/list');
};

sub list{
    my $self = shift;

    my $resources = Utils::Hr::get_all_resources($self);
    $self->stash( resources => $resources );
};


# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
