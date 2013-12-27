package Buh1::Hr; {

=encoding utf8

=head1 NAME

    Accounts controller

=cut

use Mojo::Base 'Mojolicious::Controller';
use Utils::Hr ;

sub auth{
    my ($self,$access) = @_;
    if( $self->user_role2company !~ /$access/i ){
        $self->stash( noaccess => 1 );
        return;
    }
    return(1);
};

sub add{
    my $self = shift;
    return if( !auth($self,'write|admin') );
    my $method = $self->req->method;
    if ( $method =~ /POST/ ){
    } else {
	}
};

sub list{
    my $self = shift;
    return if( !auth($self,'read|write|admin') );

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
