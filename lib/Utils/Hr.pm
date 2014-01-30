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
    my $parents1 = {};
	my $parents2 = {};
    my $sth = $dbc->get_from_sql( " SELECT DISTINCT id FROM objects $where_sql ; " ) ;
    my $id = undef;
    $sth->bind_col(1, \$id);
    while($sth->fetch){
        $parents1->{$id} = undef ;
        $parents2->{$id} = undef ;
    }
    # CHILDS
    # generate CHILD->PARENT links
    $sth = $dbc->get_from_sql( " SELECT DISTINCT id, value FROM objects $where_sql AND field = 'PARENT' ; " ) ;
    $sth->bind_col(1, \$id);
    my $parent = undef; $sth->bind_col(2,\$parent) ;
    while($sth->fetch){
        $parents1->{$parent} = {$id => undef} ;
        $parents2->{$parent} = {$id => undef} ;
    }
	my $tree = {} ;
    my $keys = {} ;
    warn "=== parent before ===" ;
    warn Dumper $parents1 ;
	make_tree_hash($parents1,$parents2, 0);
    warn "=== parent after ===" ;
    warn Dumper $parents1 ;
    return($parents1);
};

sub make_tree_hash{
	my $hash = shift ;
    my $hash_part = shift ;
    my $level = shift ;
	for my $key (keys %{$hash_part}){
        if( ref($hash_part->{$key}) eq 'HASH' ){
            make_tree_hash($hash, $hash_part->{$key}, 1 ) ;
        } else {
            if( $level ){
                delete $hash->{$key} ;
            } else {
                
            }
        }
	}
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
