package Utils::Templates; {

=encoding utf8

=head1 NAME

    Database utilites 

=cut

use 5.012000;
use strict;
use warnings;
use utf8;
use Utils::Db;

sub validate2payload{
    my $self = shift;
    my $id   = $self->param('payload');
    my $dbc = Db->new($self);
    if( !Utils::Db::is_object_exists($dbc,$id)){
        $self->redirect_to('/user/login?warning=data_not_found');
        return(0);
    }
    return(1);
};

sub authorized2edit{
    my $self = shift ;
    if( !$self->who_is_global('editor') ){
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

sub deploy_root_list{
    my $self = shift ;
    my $root_list = Utils::Db::db_get_root($self," WHERE name = 'template' ");
    $self->stash( resources_root => $root_list );
};


# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

 M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
