package Utils::Tags; {

=encoding utf8

=head1 NAME

    Utilites 

=cut

use 5.012000;
use strict;
use warnings;
use utf8;
use Utils::Db ;
use Utils::Warehouse ;
use Data::Dumper ;

my $OBJECT_NAME  = Utils::Warehouse::object_name() . ' tag' ;
my $OBJECT_NAMES = Utils::Warehouse::object_name() . ' tags' ;
sub object_name{ return($OBJECT_NAME); };
sub object_names{ return($OBJECT_NAMES); };

sub add{
    my $self = shift;
    my $pid = $self->param('payload') ;
    my $data = form2data($self);
    return(0) if !validate($self,$data);
    my $id = Utils::Db::cdb_insert_or_update($self,$data);
    my $db = Utils::Db::client($self);
    return $db->set_link(
        Utils::Warehouse::object_name(), $pid,
        object_name(), $id);
};

sub add2{
    my $self = shift;
    my $pid = $self->param('payload') ;
    my $data = form2data2($self);
    return(0) if !validate($self,$data);
    my $id = Utils::Db::cdb_insert_or_update($self,$data);
    my $db = Utils::Db::client($self);
    return $db->set_link(
        Utils::Warehouse::object_name(), $pid,
        object_name(), $id);
};

sub validate{
    my ($self,$data) = @_ ;
    my $result = 1;
    $result = 0 if !exists $data->{'name'} ;
    $result = 0 if !exists $data->{'value'} ;
    return($result);
};

sub form2data{
    my $self = shift;
    my $data = { 
        object_name => object_name(),
        creator     => Utils::User::current($self),
        } ;
    $data->{name} = Utils::trim $self->param('name')
        if Utils::trim $self->param('name');
    $data->{value} = Utils::trim $self->param('value')
        if Utils::trim $self->param('value');
    return($data);
};

sub form2data2{
    my $self = shift;
    my $data = { 
        object_name => object_name(),
        creator     => Utils::User::current($self),
        } ;
    $data->{name} = Utils::trim $self->param('name2')
        if Utils::trim $self->param('name2');
    $data->{value} = Utils::trim $self->param('value2')
        if Utils::trim $self->param('value2');
    return($data);
};

sub add_edit_post{
    my $self = shift ;
    my $data = form2data($self);
    if( validate($self,$data) ){
        my $id = Utils::Db::cdb_insert_or_update($self,$data);
        my $action = $self->stash('action') ;
        if( lc($action) eq 'add' ){
            $self->redirect_to("/warehouse/edit/$id") ;
            $self->stash('success' => 1);
        } else {
            $self->stash('success' => 1);
        }
            return(1);
    }
    $self->stash(error => 1);
    return(0) ;
};

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

 M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
