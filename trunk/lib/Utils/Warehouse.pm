package Utils::Warehouse; {

=encoding utf8

=head1 NAME

    Database utilites 

=cut

use 5.012000;
use strict;
use warnings;
use utf8;
use Utils::Db ;
use Data::Dumper ;

my $OBJECT_NAME  = 'warehouse object' ;
my $OBJECT_NAMES = 'warehouse objects' ;

sub object_name{ return($OBJECT_NAME); };
sub object_names{ return($OBJECT_NAMES); };
sub tag_object_name{ return("$OBJECT_NAME tag"); };
sub tag_object_names{ return("$OBJECT_NAMES tags"); };

sub redirect2list_or_path{
    my $self = shift;
    if ( $self->param('path') ){
        $self->redirect_to($self->param('path'));
        return;
    }
    $self->redirect_to("/warehouse/list");
};

sub validate2edit{
    my $self = shift;
    return if !$self->who_is('local','writer');
    my $id = $self->param('payload') ;
    if( !$id ){
        warn "Object not exists!";
        $self->redirect_to('/user/login?warning=data_not_found');
        return(0);
    }
    my $db = Utils::Db::client($self);
    my $objects = $db->get_objects({id => [$id]});
    if( !scalar(keys(%{$objects})) ){
        warn "Object not found!";
        $self->redirect_to('/user/login?warning=data_not_found');
        return(0);
    }
    return(1)
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

sub deploy_list_objects{
    my ($self,$name,$path) = @_;

    my $filter = $self->session->{"$OBJECT_NAMES/filter"};
    my $db = Utils::Db::client($self);
    my $objects ;
    if( !$filter ){
        $objects = get_all_objects($self) ;
    } else {
        $objects = Utils::Db::get_filtered_objects2($self, {
                name          => object_name(),
                child_names   => [Utils::Tags::object_name(),]
            });
    }
    $self->stash( objects => $objects ) if scalar(keys(%{$objects}));
    return($objects);
};

sub get_all_objects{
    my $self = shift ;
    my $db = Utils::Db::client($self) ;
    return $db->get_filtered_objects({
            self          => $self,
            name          => object_name(),
            names         => object_names(),
            exist_field   => 'description',
            filter_value  => undef,
            filter_prefix => " field='description' ",
            result_fields => ['description',],
        });
};

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

 M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
