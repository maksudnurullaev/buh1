package Buh1::Catalog; {

=encoding utf8

=head1 NAME

    Accounts controller

=cut

use Mojo::Base 'Mojolicious::Controller';
use Utils::Catalog ;
use Utils::Files ;
use Utils::Calculations ;
use Data::Dumper ;

sub add{
    my $self = shift;

    my $method = $self->req->method;
    if ( $method =~ /POST/ ){
        my $data = Utils::Catalog::form2data($self);
        if( Utils::Catalog::validate($self,$data) ){
            Utils::Db::cdb_insert_or_update($self,$data);
            $self->stash(success => 1);
            $self->redirect_to('/catalog/list');
        }
    }
};

sub list{
    my $self = shift;
    $self->stash( resources_root => Utils::Catalog::get_root_objects($self) );
};

sub edit{
    my $self = shift;

    if( $self->req->method eq 'POST' ){
        my $data = Utils::Catalog::form2data($self);
        $self->stash(success => 1);
        Utils::Db::cdb_insert_or_update($self,$data);
    }

    # final action
    my $id = $self->param('payload');
    Utils::Db::cdb_deploy($self,$id);
    $self->stash( resources_root => Utils::Catalog::get_root_objects($self) );
};

sub del{
    my $self = shift;
    my $method = $self->req->method ;
    my $id = $self->param('payload');
    if( uc($method) eq 'POST' ){
        my $dbc = Utils::Db::client($self) ;
        $dbc->del($id);
        $self->redirect_to('/catalog/list');
    }
    # final action
    Utils::Db::cdb_deploy($self,$id);
};

sub move{
    my $self = shift;
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
    Utils::Db::cdb_deploy($self,$id);
};

sub make_root{
    my $self = shift;
    my $id   = $self->param('payload');
    my $dbc = Utils::Db::client($self);
    $dbc->child_make_root($id);
    $self->redirect_to("/catalog/move/$id");
};

# files part

sub files_update{
    my $self = shift;
    my $id = $self->param('payload');
    my $fileid = $self->param('fileid');

    Utils::Db::cdb_deploy($self,$id);
    Utils::Files::deploy($self,$id,$fileid);
};

sub files_update_desc{
    my $self = shift;
    my $id = $self->param('payload');
    my $fileid = $self->param('fileid');

    if( $self->req->method  eq 'POST' ){
        Utils::Files::update_desc($self);
    }
    $self->redirect_to("/catalog/files_update/$id?fileid=$fileid");
};

sub files_update_file{
    my $self = shift;
    my $id = $self->param('payload');
    my $fileid = $self->param('fileid');

    if( $self->req->method  eq 'POST' ){
        if( Utils::Files::update_file($self) ){
            $self->redirect_to("/catalog/files_update/$id?fileid=$fileid");
            return;
        } else {
             $self->stash( error => 1 );
        }
    }
};

sub files_del{
    my $self = shift;
    my $id = $self->param('payload');
    Utils::Files::del_file($self);
    $self->redirect_to("/catalog/files/$id");
};

sub files_add_new{
    my $self = shift;

    my $id = $self->param('payload');

    if( $self->req->method  eq 'POST' ){
        if( $self->req->error ){
            $self->stash( error => 1 );
            return;
        }
        if( Utils::Files::add_new($self) ){
               $self->redirect_to("/catalog/files/$id");
            return;
        } else {
             $self->stash( error => 1 );
        }
    }

    Utils::Db::cdb_deploy($self,$id);
};

sub files{
    my $self = shift;

    my $id   = $self->param('payload');

    $self->stash(files=>Utils::Files::file_list4id($self,$id));

    Utils::Db::cdb_deploy($self,$id);
};

# calculations part

sub calculations{
    my $self = shift;

    my $id = $self->param('payload');
    Utils::Db::cdb_deploy($self,$id);
    my $dbc = Utils::Db::client($self);
    my $calculations = $dbc->get_links($id,'calculation',['description']);
    $self->stash( calculations => $calculations );
};

sub calculations_add{
    my $self = shift ;

    my $id = $self->param('payload');
    if ( $self->req->method =~ /POST/ ){
        my $data = Utils::Calculations::form2data($self);
        if( Utils::Calculations::validate($self,$data) ){
            if( defined $self->param('use_template') ){
                my $cid = $self->param('calculation_template');
                my $db = Utils::Db::main($self);
                my $template = $db->get_objects({ id => [$cid] })->{$cid} ;
                delete $template->{id} ;
                delete $template->{description} ;
                delete $template->{creator} ;
                delete $template->{object_name} ;
                for my $key (keys %{$template}){
                    $data->{$key} = $template->{$key} ;
                }
            }
            my $dbc = Utils::Db::client($self);
            my $cid = $dbc->insert($data);
            $dbc->set_link('catalog',$id,'calculation',$cid);
            $self->redirect_to("/catalog/calculations_edit/$id?id=$cid");
        } else {
           $self->stash('description_class' => 'error');
           $self->stash('error' => 1);
        }
    }
    # finish
    Utils::Db::cdb_deploy($self,$id);
    my $calculcation_templates_date = Utils::Calculations::get_list_as_select_data(
            $self, Utils::Calculations::get_db_list($self));
    $self->stash( calculation_templates => $calculcation_templates_date );
};

sub calculations_edit{
    my $self = shift;


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
                $dbc->set_link('catalog',$id,'calculation',$new_cid);
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
    Utils::Calculations::deploy_result($self, $data) ;
};

sub calculations_update_fields{
    my $self = shift;

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
