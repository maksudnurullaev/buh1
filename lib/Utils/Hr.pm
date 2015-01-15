package Utils::Hr; {

=encoding utf8

=head1 NAME

    Utilites 

=cut

use 5.012000;
use strict;
use warnings;
use utf8;
use Utils::Db;
use Data::Dumper;

sub get_params3{
    my $self = shift ;
    return($self->param('payload'),
           $self->param('id'),
           $self->req->method);
};

sub calculcation_edit_params{
    my $self = shift ;
    my @result = ($self->param('payload'),
           $self->param('id'),
           $self->req->method);
    return(@result);
};

sub calculation_edit_post{
    my $self = shift ;
    my ($id,$cid) = calculcation_edit_params($self); 
    my $data = Utils::Calculations::form2data($self);
    if( Utils::Calculations::validate($self,$data) ){
        Utils::Db::cdb_insert_or_update($self,$data);
        $self->stash(success => 1);
    } else {
        $self->stash(error => 1);
    }
};

sub authorized2read{
    my $self = shift;
    if( !$self->who_is_local('reader') ){
        $self->redirect_to('/user/login?warning=access');
        return(0);
    }
    return(1);
};

sub authorized2edit{
    my $self = shift;
    if( !$self->who_is_local('writer') ){
        $self->redirect_to('/user/login?warning=access');
        return(0);
    }
    return(1);
};

sub form2data{
    my $self = shift;
    my $data = { 
        object_name => $self->param('oname'),
        creator     => Utils::User::current($self),
        } ;
	$data->{id} = $self->param('id') if $self->param('id') ;
    $data->{description} = Utils::trim $self->param('description')
        if Utils::trim $self->param('description');
    return($data)
};

sub validate{
    my ($self,$data) = @_ ;
    if( !exists $data->{description} ){
        $self->stash('description_class' => 'error');
        $self->stash('error' => 1);
        return(0);
    }
    return(1);
};

sub get_root_objects{
    my $self = shift ;
    return(Utils::Db::cdb_get_root($self," WHERE name = 'hr' "));
};


# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

 M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
