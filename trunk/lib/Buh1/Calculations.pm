package Buh1::Calculations; {

=encoding utf8

=head1 NAME

    Accounts controller

=cut

use Mojo::Base 'Mojolicious::Controller';
use Utils::Calculations ;
use Utils::Db ;
use Data::Dumper ;

sub list{
    my $self = shift;
    $self->stash( calculations 
        => Utils::Db::db_get_objects($self,{name=>['calculation']}));
};

sub add{
    my $self = shift;
    if( !$self->is_user() ){ 
        $self->redirect_to('/user/login'); 
        return ; 
    }

    my $method = $self->req->method;
    if ( $method =~ /POST/ ){
        my $data = Utils::Calculations::form2data($self);
        if( Utils::Calculations::validate($self,$data) ){
            Utils::Db::db_insert_or_update($self,$data);
            $self->stash(success => 1);
            $self->redirect_to('/calculations/list');
        }
	}
};

sub edit{
    my $self = shift;
    if( !$self->is_user() ){ 
        $self->redirect_to('/user/login'); 
        return ; 
    }
    my $id = $self->param('payload');

    my $method = $self->req->method;
    if ( $method =~ /POST/ ){
        my $data = Utils::Calculations::form2data($self);
        if( Utils::Calculations::validate($self,$data) ){
            Utils::Db::db_insert_or_update($self,$data);
            $self->stash(success => 1);
        }
	}
    Utils::Db::db_deploy($self,$id);
};

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
