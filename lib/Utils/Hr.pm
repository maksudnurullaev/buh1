package Utils::Hr; {

=encoding utf8

=head1 NAME

    Database utilites 

=cut

use 5.012000;
use strict;
use warnings;
use utf8;
use Utils::Db;
use Data::Dumper;

my ($HR_DESCRIPTOR_NAME,$HR_PERSON_NAME) = 
   ('hr descriptor',    'hr person') ;

sub del{
    my ($self,$id) = @_;
    my $dbc = Utils::Db::client($self) ;
    $dbc->del($id);
};

sub insert_or_update{
    my ($self,$data) = @_ ;
	my $dbc = Utils::Db::client($self) ;
    if( exists($data->{id}) ){
        $dbc->update( $data );
    } else {
        $dbc->insert( $data );
    }
    $self->stash(success => 1);
};

sub auth{
    my ($self,$access) = @_;
    if( !defined($self->user_role2company) 
		|| $self->user_role2company !~ /$access/i ){
        $self->redirect_to('user/login');
		return;
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

sub set_parent{
    my $self = shift ;
    my $dbc = Utils::Db::client($self);

    my $data = { 
        object_name => $self->param('oname'), 
        id          => $self->param('payload'), 
        PARENT      => $self->param('parent') } ;
    $dbc->update($data) ;
};

sub get_resources{
    my $self = shift;
    my $dbc = Utils::Db::client($self);
    if( !$dbc ){
        warn "Could not connect to client's db!";
        return(undef);
    }
    return $dbc->get_objects( { name => [ $HR_DESCRIPTOR_NAME, $HR_PERSON_NAME ] } ) ;
};

sub get_tree{
    my ($self,$where_sql) = @_ ;
    return if !$where_sql ;

    my $dbc = Utils::Db::client($self);
    # PARENTS
    # we needs two parents: one for get key->object, second for traverse
    my $parents = {};
    my $sth = $dbc->get_from_sql( " SELECT DISTINCT id FROM objects $where_sql ; " ) ;
    my $id = undef;
    $sth->bind_col(1, \$id);
    while($sth->fetch){
        $parents->{$id} = undef ;
    }
    # CHILDS
    # generate CHILD->PARENT links
    $sth = $dbc->get_from_sql( " SELECT DISTINCT id, value FROM objects $where_sql AND field = 'PARENT' ; " ) ;
    $sth->bind_col(1, \$id);
    my $parent = undef; $sth->bind_col(2,\$parent) ;
    while($sth->fetch){
        $parents->{$parent} = $id ;
    }
	my $tree = {} ;
    my $keys = {} ;
    warn "=== original ===" ;
    warn Dumper $parents ;
    warn "=== parent after ===" ;
    warn Dumper make_tree_hash($parents);
    return($parents);
};

sub make_tree_hash{
	my $hash = shift ;
	my $result = {} ;
	for my $child (sort keys %{$hash}){
		my $parent = $hash->{$child} ;
		if( $parent ){
			$result->{$parent} = find_child($hash,$child) ;
		} 
	}
	return($result);
};

sub find_child{
	my $hash = shift ;
	my $parent = shift ;
	my $result = {} ;
	for my $c (keys %{$hash}){
		if( $hash->{$c} && $hash->{$c} eq $parent ){
			$result->{$parent}{$c} = find_child($hash,$c);
			last;
		} 
	}
	return($result);
};

sub deploy{
    my ($self,$id) = @_ ;
    return if !$id ;
    my $dbc = Utils::Db::client($self);
    if( $dbc ){
        my $objects = $dbc->get_objects( { id => [$id] } );
        if( $objects && exists($objects->{$id}) ){
            my $object = $objects->{$id};
            for my $key (keys %{$object}){
                $self->stash($key => $object->{$key});
            }
        }
    }
};

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

 M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
