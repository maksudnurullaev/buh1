package Buh1::Hr; {

=encoding utf8

=head1 NAME

    Accounts controller

=cut

use Mojo::Base 'Mojolicious::Controller';
use Utils::Hr ;
use Data::Dumper ;

sub auth{
    my ($self,$access) = @_;
    if( $self->user_role2company !~ /$access/i ){
        $self->stash( noaccess => 1 );
        return;
    }
    return(1);
};

sub validate{
    my $self = shift;
    my $data = { 
        object_name => $self->param('oname'),
        creator     => Utils::User::current($self),
    };
	$data->{id} = $self->param('id') if $self->param('id') !~ /new/i ;
    $data->{description} = Utils::trim $self->param('description')
        if Utils::trim $self->param('description');
    if( !exists $data->{description} ){
        $data->{error} = 1 ;
        $self->stash('description_class' => 'error');
        $self->stash('error' => 1);
    }
    return($data)
};

sub add{
    my $self = shift;
    return if( !auth($self,'write|admin') );
    my $method = $self->req->method;
    if ( $method =~ /POST/ ){
        # 1. validate
        my $data = validate($self);
        if( !exists($data->{error}) ){
            warn Dumper $data ;
        }
        # 2. add object to db
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
