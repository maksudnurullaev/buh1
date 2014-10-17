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
    my ($self,$id,$prefix) = @_ ;
    return if !$id ;
    my $dbc = Db->new();
    return(deploy($self,$dbc,$id,$prefix));
};

sub cdb_deploy{
    my ($self,$id,$prefix) = @_ ;
    return if !$id ;
    my $dbc = client($self);
    return(deploy($self,$dbc,$id,$prefix));
};

sub deploy{
    my ($self,$dbc,$id,$prefix) = @_ ;
    return(0) if !$dbc || !$id ;

    my $objects = $dbc->get_objects( { id => [$id] } );
    if( $objects && exists($objects->{$id}) ){
        my $object = $objects->{$id};
        for my $key (keys %{$object}){
            if( $prefix ){
                $self->stash("$prefix.$key" => $object->{$key});
            } else {
                $self->stash($key => $object->{$key});
            }
        }
        return($object);
    }
    return(undef);
};

sub cdb_execute_sql{
	my($self,$sql) = @_ ;
	return if !$sql ;
	my $dbc = client($self);
	$dbc->get_from_sql($sql);
};

sub db_execute_sql{
	my($sels,$sql) = @_ ;
	return if !$sql ;
	my $dbc = Db->new();
	$dbc->get_from_sql($sql);
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
        return( $dbc->update($data) );
    } else {
        return( $dbc->insert($data) );
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
