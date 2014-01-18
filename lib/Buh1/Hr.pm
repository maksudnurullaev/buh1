package Buh1::Hr; {

=encoding utf8

=head1 NAME

    Accounts controller

=cut

use Mojo::Base 'Mojolicious::Controller';
use Utils::Hr ;
use Data::Dumper ;

sub add{
    my $self = shift;
    return if( !Utils::Hr::auth($self,'write|admin') );
    my $method = $self->req->method;
    if ( $method =~ /POST/ ){
        # 1. validate
        my $data = Utils::Hr::form2data($self);
        if( Utils::Hr::validate($self,$data) ){
            warn 'Utils::Hr::add($self, $data);';
        }
        # 2. add object to db
    } else {
	}
};

sub list{
    my $self = shift;
    return if( !Utils::Hr::auth($self,'read|write|admin') );

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
