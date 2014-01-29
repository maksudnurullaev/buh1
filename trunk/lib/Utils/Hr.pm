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
    # ===============
    my $parents1 = {};
	my $parents2 = {};
    my $sth = $dbc->get_from_sql( " SELECT DISTINCT id FROM objects WHERE name LIKE 'hr%' " ) ;
    my $id = undef;
    $sth->bind_col(1, \$id);
    while($sth->fetch){
        $parents1->{$id} = undef ;
        $parents2->{$id} = undef ;
    }

    $sth = $dbc->get_from_sql( " SELECT DISTINCT id, value FROM objects WHERE name LIKE 'hr%' AND field = 'PARENT' " ) ;
    $sth->bind_col(1, \$id);
    my $parent = undef; $sth->bind_col(2,\$parent);
    while($sth->fetch){
        $parents1->{$parent} = {$id => undef} ;
        $parents2->{$parent} = {$id => undef} ;
    }
    warn Dumper $parents1;
	my $tree = {} ;
	make_tree($parents1, {}, $tree);
	warn Dumper $tree ;
    # =================
    # final
    $dbc->get_objects( { name => [ $HR_DESCRIPTOR_NAME, $HR_PERSON_NAME ] } ) ;
};

sub make_tree{
	my $hash = shift ;
	my $keys = shift ;
	my $tree = shift ;
	return if ref($hash) ne 'HASH' ;
	for my $key (keys %{$hash}){
		if( !exists($keys->{$key}) ){
			warn "-> $key";
			$keys->{$key} = undef;
			if( $hash->{$key} && $hash->{$hash->{$hash}} ){
				$tree->{$key} = { $hash->{$key} => $hash->{$hash->{$key}} } ; 
				make_tree($hash->{$hash->{$key}},$keys,$tree->{$key}{$hash->{$key}}) ;
			} else {
				$tree->{$key} = undef ;
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
