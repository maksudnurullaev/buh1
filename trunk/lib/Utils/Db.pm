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
use Utils;
use DbClient;
use Db;

sub client{
    my $self = shift;
    my $db_client = new DbClient($self);
    return($db_client) if $db_client && $db_client->is_valid ;
    return(undef);
};    

sub main{
    return(Db->new(shift));
};

sub db_get_objects{
    my $self = shift;
    my $params = shift;
    my $db = new Db($self);
    return($db->get_objects($params));
};

sub cdb_get_objects{
    my $self = shift;
    my $params = shift;
    my $db = client($self);
    return($db->get_objects($params));
};

sub cdb_get_links{
    my ($self,$pid,$lname,$fields) = @_ ;
    my $result = {} ;
    return($result) if !$pid || !$lname ;
    my $db = client($self);
    return($db->get_links($pid,$lname,$fields));
};

sub cdb_get_unique_field{
    my ($self,$object_name,$field_name,$pid) = @_ ;
    my $sql = "SELECT DISTINCT $field_name FROM OBJECTS WHERE name = '$object_name' AND field = 'name' ORDER BY 1 ASC ;" ;
    my $db = client($self);
    my $sth = $db->get_from_sql( $sql ) ;
    my $value;
    $sth->bind_col(1, \$value);
    my $result = [] ;
    my $existance_links = $db->get_links($pid,$object_name,['name']) ;
    while($sth->fetch){ 
        push @{$result}, $value if !_exists_in($existance_links,$value) ; 
    }
    return($result);
};

sub _exists_in{
    my ($hash_arr,$value) = @_;
    for my $key (keys %{$hash_arr}){
        return(1) if $value eq $hash_arr->{$key}{'name'} ;
    }
    return(0);
};

sub db_deploy{
    my ($self,$id,$prefix) = @_ ;
    return if !$id ;
    my $dbc = Db->new($self);
    return(deploy($self,$dbc,$id,$prefix));
};

sub cdb_deploy{
    my ($self,$id,$prefix) = @_ ;
    return if !$id ;
    my $dbc = client($self);
    return(deploy($self,$dbc,$id,$prefix));
};

sub is_object_exists{
    my ($dbc,$id) = @_ ;
    return(0) if !$dbc || !$id ;

    my $objects = $dbc->get_objects( { id => [$id] } );
    return($objects && exists($objects->{$id}));
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
    my($self,$sql) = @_ ;
    return if !$sql ;
    my $dbc = Db->new($self);
    $dbc->get_from_sql($sql);
};

sub db_insert_or_update{
    my ($self,$data) = @_ ;
    my $dbc = Db->new($self) ;
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
    my $db = Db->new($self) ;
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

sub get_filtered_objects2{
    my ($self,$params) = @_ ;
    my $result = {};
    # 1. Get filtered object ids
    my $sql = sql4ids2filtered_objects2($params) ;
    my $db  = Utils::Db::client($self);
    my $sth = $db->get_from_sql($sql);
    my $ids = [];
    for my $id (@{$sth->fetchall_arrayref()}){
        push @{$ids}, $id->[0] ;
    }
    return($result) if !scalar(@{$ids}) ;
    my $paginator = Utils::get_paginator($self,$params->{object_names},scalar(@{$ids}));
    $self->stash(paginator => $paginator);
    my ($page,$pages,$pagesize) = @{$paginator} ;
    my $start_index = ($page - 1) * $pagesize ;
    my $end_index = $start_index + $pagesize - 1 ;
    my $rids = []; @{$rids} = (reverse @{$ids})[$start_index..$end_index];
    $result = $db->get_objects({id => $rids});
    return($result);
};

sub sql4ids2filtered_objects2{
    my $params = shift;
    return if !$params ;
    my $child_names;
    for my $child_name (@{$params->{child_names}}){
        $child_names .= ',' if $child_names;
        $child_names .= "'$child_name'" ;
    }
    return 
        " SELECT DISTINCT id FROM OBJECTS " .
        " WHERE name = '$params->{object_name}' " . 
        " AND value LIKE '%$params->{filter_value}%' " . 
        " UNION " .
        " SELECT DISTINCT value AS id FROM objects WHERE name = '_link_' AND id IN ( " . 
        "  SELECT DISTINCT id FROM objects WHERE name = '_link_' AND field = '$params->{object_name}' AND id IN ( " .
        "   SELECT DISTINCT id FROM OBJECTS  WHERE name IN ($child_names) AND value LIKE '%$params->{filter_value}%')) ; " ;
};

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

 M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
