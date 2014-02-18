package Buh1::Calculations; {

=encoding utf8

=head1 NAME

    Accounts controller

=cut

use Mojo::Base 'Mojolicious::Controller';
use Utils::Calculations ;
use Utils::Db ;
use Data::Dumper ;

sub auth{
    my $self = shift;
    if( !$self->is_user() ){ 
        $self->redirect_to('/user/login'); 
        return ; 
    }
    return(1);
};

sub list{
    my $self = shift;
    $self->stash( calculations => Utils::Calculations::get_db_list($self));
};

sub add{
    my $self = shift;
    return if !auth($self) ;

    my $method = $self->req->method;
    if ( $method =~ /POST/ ){
        my $data = Utils::Calculations::form2data($self);
        if( Utils::Calculations::validate($self,$data) ){
            Utils::Db::db_insert_or_update($self,$data);
            $self->stash(success => 1);
            $self->redirect_to('/calculations/list');
        } else {
           $self->stash('description_class' => 'error');
           $self->stash('error' => 1);
        }
    }
};

sub test{
    my $self = shift;

    my $id = $self->param('payload');
    my $method = $self->req->method;
    my $data = {} ;
    if ( $method =~ /POST/ ){
        my @param = $self->param ;
        for my $key (@param){
            $data->{$key} = $self->param($key);
            $self->stash( $key => $self->param($key) ) ;
        }
    } else {
        $data = Utils::Db::db_deploy($self,$id) ;
    }
    Utils::Calculations::deploy_result($self, $data) ;
};

sub edit{
    my $self = shift;
    return if !auth($self) ;

    my $id = $self->param('payload');
    my $method = $self->req->method;
    if ( $method =~ /POST/ ){
        my $data = Utils::Calculations::form2data($self);
        if( Utils::Calculations::validate($self,$data) ){
            Utils::Db::db_insert_or_update($self,$data);
            $self->stash(success => 1);
        }
    }
    my $data = Utils::Db::db_deploy($self,$id) ;
    Utils::Calculations::deploy_result($self, $data) ;
};

sub update_fields{
    my $self = shift;
    return if !auth($self) ;

    my $id = $self->param('payload');
    my $method = $self->req->method;
    if ( $method =~ /POST/ ){
        my $data = Utils::Calculations::form2data_fields($self);
        # delete all old definitions
        Utils::Db::db_execute_sql($self, " delete from objects where id = '$id' and field like 'f_%' ; " ) ;
        # insert new ones
        Utils::Db::db_insert_or_update($self,$data);
        $self->stash(success => 1);
    }
    $self->redirect_to("/calculations/edit/$id");
};

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
