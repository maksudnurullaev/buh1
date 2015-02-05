package Buh1::Catalog; {

=encoding utf8

=head1 NAME

    Accounts controller

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

# calculations part
sub calculations_edit{
    my $self = shift;
    return if !$self->who_is('local','writer');

    my $id = $self->param('payload');
    my $cid = $self->param('id') ; 
    my $method = $self->req->method;
    if ( $method =~ /POST/ ){
        my $data = Utils::Calculations::form2data($self);
        if( Utils::Calculations::validate($self,$data) ){
            if( defined $self->param('make_copy') ){
                my $dbc = Utils::Db::client($self);
                my $template = $dbc->get_objects({ id => [$cid] })->{$cid} ;
                delete $data->{id} ;
                delete $template->{id} ;
                delete $template->{description} ;
                for my $key (keys %{$template}){
                    $data->{$key} = $template->{$key} if $key !~ /^_/ ;
                }
                my $new_cid = $dbc->insert($data);
                $dbc->set_link($id,$new_cid);
                $self->redirect_to("/catalog/calculations/$id");
                return;
            } else {
                Utils::Db::cdb_insert_or_update($self,$data);
                $self->stash(success => 1);
            }
        }
    }
    # finish
    Utils::Db::cdb_deploy($self,$id, 'catalog');
    my $data = Utils::Db::cdb_deploy($self,$cid) ;
    Utils::Calculations::deploy_result($self, $data) if $data ;
};

sub calculations_test{
    my $self = shift;
    return if !$self->who_is('local','reader');

    my ($id,$cid,$method) = Utils::Catalog::get_params3($self);
    my $data = {} ;
    if ( $method =~ /POST/ ){
        my @param = $self->param ;
        for my $key (@param){
            $data->{$key} = $self->param($key);
            $self->stash( $key => $self->param($key) ) ;
        }
    } else {
        $data = Utils::Db::cdb_deploy($self,$cid) ;
        if( !$data ){
            $self->stash(error => 1);
            return ;
        }
    }
    Utils::Db::cdb_deploy($self,$id, 'catalog');
    Utils::Calculations::deploy_result($self, $data) if $data ;
};

sub calculations_update_fields{
    my $self = shift;
    return if !$self->who_is('local','writer');

    my $id = $self->param('payload');
    my $cid = $self->param('id') ; 
    my $method = $self->req->method;
    if ( $method =~ /POST/ ){
        my $data = Utils::Calculations::form2data_fields($self);
        # delete all old definitions
        Utils::Db::cdb_execute_sql($self, " delete from objects where id = '$cid' and field like 'f_%' ; " ) ;
        # insert new ones
        Utils::Db::cdb_insert_or_update($self,$data);
        $self->stash(success => 1);
    }
    $self->redirect_to("/catalog/calculations_edit/$id?id=$cid") ;
};

sub calculations_delete{
    my $self = shift;
    return if !$self->who_is('local','writer');

    my $id = $self->param('payload');
    my $cid = $self->param('id') ; 
    my $dbc = Utils::Db::client($self);
    $dbc->del_link($id,$cid);
    $dbc->del($cid);
    $self->redirect_to("/catalog/calculations/$id") ;
};


# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
