package Utils::Db; {

=encoding utf8

=head1 NAME

    Database utilites 

=cut

use 5.012000;
use strict;
use warnings;
use utf8;
use Data::Dumper;
use DbClient;
use Db;

sub client{
    my $self = shift;
    if ( $self && $self->session('company id') ){
		my $db_client = new DbClient($self->session('company id'));
        return($db_client) if $db_client->is_valid ;
    }
    return(undef);
};    

sub main{
    return(Db->new());
};

sub db_get_objects{
    my $self = shift;
    my $params = shift;
    my $db = new Db;
    return($db->get_objects($params));
};

sub cdb_get_objects{
    my $self = shift;
    my $params = shift;
    my $db = client($self);
    return($db->get_objects($params));
};

sub db_deploy{
    my ($self,$id) = @_ ;
    return if !$id ;
    my $dbc = Db->new();
    deploy($self,$dbc,$id);
};

sub cdb_deploy{
    my ($self,$id) = @_ ;
    return if !$id ;
    my $dbc = client($self);
    deploy($self,$dbc,$id);
};

sub deploy{
    my ($self,$dbc,$id) = @_ ;
    my $objects = $dbc->get_objects( { id => [$id] } );
    if( $objects && exists($objects->{$id}) ){
        my $object = $objects->{$id};
        for my $key (keys %{$object}){
            $self->stash($key => $object->{$key});
        }
    }
};

sub db_insert_or_update{
    my ($self,$data) = @_ ;
	my $dbc = Db->new() ;
    insert_or_update($dbc,$data);
};

sub cdb_insert_or_update{
    my ($self,$data) = @_ ;
	my $dbc = client($self) ;
    insert_or_update($dbc,$data);
};

sub insert_or_update{
    my ($dbc,$data) = @_ ;
    if( exists($data->{id}) ){
        $dbc->update( $data );
    } else {
        $dbc->insert( $data );
    }
};

sub db_get_root{
    my ($self,$sql_where) = @_ ;
    return(undef) if !$sql_where ;
    my $db = Db->new() ;
    return(get_root($db,$sql_where));
};

sub cdb_get_root{
    my ($self,$sql_where) = @_ ;
    return(undef) if !$sql_where ;
    my $dbc = client($self);
    return(get_root($dbc,$sql_where));
};

sub get_root{
    my ($db,$sql_where) = @_ ;
    my $resource_root = $db->get_root_parents($sql_where) ;
    my $result = {};
    for my $pid (keys %{$resource_root}){
        $result->{ $pid } = $db->get_parent_childs($pid,['description','CHILDREN']) ;
    }
    return( $result );
};


# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

 M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
