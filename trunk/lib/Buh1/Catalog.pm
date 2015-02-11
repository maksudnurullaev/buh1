package Buh1::Catalog; {

=encoding utf8

=head1 NAME

    Catalog controller

=cut

use 5.012000;
use strict;
use warnings;
use utf8;
use Mojo::Base 'Mojolicious::Controller';
use Utils::Catalog ;
use Utils::Files ;
use Utils::Calculations ;
use Data::Dumper ;

sub add{
    my $self = shift;
    return if !$self->who_is('local','writer');

    my $method = $self->req->method;
    if ( $method =~ /POST/ ){
        my $data = Utils::Catalog::form2data($self);
        if( Utils::Catalog::validate($self,$data) ){
            Utils::Db::cdb_insert_or_update($self,$data);
            $self->stash(success => 1);
            $self->redirect_to('/catalog/list');
        } else { $self->stash(error => 1) }
    }
};

sub list{
    my $self = shift;
    return if !$self->who_is('local','reader');
    $self->stash( resources_root => Utils::Catalog::get_root_objects($self) );
};

sub edit{
    my $self = shift;
    return if !$self->who_is('local','reader');

    if( $self->req->method eq 'POST' ){
        return if !$self->who_is('local','writer');
        my $data = Utils::Catalog::form2data($self);
        if( Utils::Catalog::validate($self,$data) ){
            Utils::Db::cdb_insert_or_update($self,$data);
            $self->stash(success => 1);
        } else { $self->stash(error => 1) }
    }

    # final action
    my $id = $self->param('payload');
    Utils::Db::cdb_deploy($self,$id,'catalog');
    $self->stash( resources_root => Utils::Catalog::get_root_objects($self) );
};

sub del{
    my $self = shift;
    return if !$self->who_is('local','writer');

    my $method = $self->req->method ;
    my $id = $self->param('payload');
    if( uc($method) eq 'POST' ){
        my $dbc = Utils::Db::client($self) ;
        $dbc->del($id);
        $self->redirect_to('/catalog/list');
    }
    # final action
    Utils::Db::cdb_deploy($self,$id,'catalog');
};

sub move{
    my $self = shift;
    return if !$self->who_is('local','writer');

    my $method = $self->req->method ;
    my $id = $self->param('payload');

    if( $method eq 'POST' ){
        my $new_parent = $self->param('new_parent');
        my $parent = $self->param('parent');
        
        if( !$new_parent || ($parent && $parent eq $new_parent) ){
            $self->stash( error => 1 );
        } else {
            my $dbc = Utils::Db::client($self);
            $dbc->child_set_parent($id,$new_parent);
        }
    }
    $self->stash( resources_root => Utils::Catalog::get_root_objects($self) );
    # final action
    Utils::Db::cdb_deploy($self,$id,'catalog');
};

sub make_root{
    my $self = shift;
    return if !$self->who_is('local','writer');

    my $id   = $self->param('payload');
    my $dbc = Utils::Db::client($self);
    $dbc->child_make_root($id);
    $self->redirect_to("/catalog/move/$id");
};

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
