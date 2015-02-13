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
    my ($self,$id,$prefix,$params) = @_ ;
    return if !$id ;
    my $dbc = Db->new($self);
    return(deploy($self,$dbc,$id,$prefix,$params));
};

sub cdb_deploy{
    my ($self,$id,$prefix,$params) = @_ ;
    return if !$id ;
    my $dbc = client($self);
    return(deploy($self,$dbc,$id,$prefix,$params));
};

sub is_object_exists{
    my ($dbc,$id) = @_ ;
    return(0) if !$dbc || !$id ;

    my $objects = $dbc->get_objects( { id => [$id] } );
    return($objects && exists($objects->{$id}));
};

sub deploy{
    my ($self,$dbc,$id,$prefix,$params) = @_ ;
    return(0) if !$dbc || !$id ;

    my $_params = { id => [$id] };
    if( $params ){
        for my $key( keys %{$params} ){
            $_params->{$key} = $params->{$key} ;
        }
    }
    my $objects = $dbc->get_objects( $_params );
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

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

 M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
