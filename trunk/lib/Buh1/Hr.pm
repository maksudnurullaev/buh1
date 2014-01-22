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
        my $data = Utils::Hr::form2data($self);
        if( Utils::Hr::validate($self,$data) ){
            Utils::Hr::insert_or_update($self,$data);
            $self->redirect_to('/hr/list');
        }
	}
};

sub list{
    my $self = shift;
    return if( !Utils::Hr::auth($self,'read|write|admin') );

    my $resources = Utils::Hr::get_all($self);
    $self->stash( resources => $resources );
};

sub edit{
    my $self = shift;
    return if( !Utils::Hr::auth($self,'write|admin') );
    
    my $method = $self->req->method ;
    if( $method eq 'POST' ){
        my $data = Utils::Hr::form2data($self);
        Utils::Hr::insert_or_update($self,$data);
    }
    # final action
    my $id = $self->param('payload');
    Utils::Hr::deploy($self,$id);
};

sub del{
    my $self = shift;
    return if( !Utils::Hr::auth($self,'write|admin') );

    my $method = $self->req->method ;
    my $id = $self->param('payload');
    if( uc($method) eq 'POST' ){
        warn "going delete $id ";
        Utils::Hr::del($self,$id);
        $self->redirect_to('/hr/list');
    }
    # final action
    Utils::Hr::deploy($self,$id);
};

sub move{
    my $self = shift;
    return if( !Utils::Hr::auth($self,'write|admin') );

    my $method = $self->req->method ;
    my $id = $self->param('payload');
#    if( uc($method) eq 'POST' ){
#        warn "going delete $id ";
#        Utils::Hr::del($self,$id);
#        $self->redirect_to('/hr/list');
#    }
    # final action
    Utils::Hr::deploy($self,$id);
};


# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
