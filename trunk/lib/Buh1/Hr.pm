package Buh1::Hr; {

=encoding utf8

=head1 NAME

    Accounts controller

=cut

use Mojo::Base 'Mojolicious::Controller';
use Utils::Hr ;
use Utils::Files ;
use Data::Dumper ;

sub add{
    my $self = shift;
    return if( !Utils::Hr::auth($self,'write|admin') );
    my $method = $self->req->method;
    if ( $method =~ /POST/ ){
        my $data = Utils::Hr::form2data($self);
        if( Utils::Hr::validate($self,$data) ){
            Utils::Db::cdb_insert_or_update($self,$data);
            $self->stash(success => 1);
            $self->redirect_to('/hr/list');
        }
	}
};

sub list{
    my $self = shift;
    return if( !Utils::Hr::auth($self,'read|write|admin') );

    $self->stash( resources_root => Utils::Hr::get_root_objects($self) );
};

sub edit{
    my $self = shift;
    return if( !Utils::Hr::auth($self,'write|admin') );
    
    my $method = $self->req->method ;
    if( $method eq 'POST' ){
        my $data = Utils::Hr::form2data($self);
        $self->stash(success => 1);
        Utils::Db::cdb_insert_or_update($self,$data);
    }
    # final action
    my $id = $self->param('payload');
    Utils::Db::cdb_deploy($self,$id);
    $self->stash( resources_root => Utils::Hr::get_root_objects($self) );
};

sub del{
    my $self = shift;
    return if( !Utils::Hr::auth($self,'write|admin') );

    my $method = $self->req->method ;
    my $id = $self->param('payload');
    if( uc($method) eq 'POST' ){
        my $dbc = Utils::Db::client($self) ;
        $dbc->del($id);
        $self->redirect_to('/hr/list');
    }
    # final action
    Utils::Db::cdb_deploy($self,$id);
};

sub files_update{
    my $self = shift;
    return if( !Utils::Hr::auth($self,'write|admin') );

    my $id = $self->param('payload');
    my $fileid = $self->param('fileid');

    Utils::Db::cdb_deploy($self,$id);
    Utils::Files::deploy($self,$id,$fileid);
};

sub files_update_desc{
    my $self = shift;
    return if( !Utils::Hr::auth($self,'write|admin') );

    my $id = $self->param('payload');
    my $fileid = $self->param('fileid');

	if( $self->req->method  eq 'POST' ){
        Utils::Files::update_desc($self);
	}
    $self->redirect_to("/hr/files_update/$id?fileid=$fileid");
};

sub files_update_file{
    my $self = shift;
    return if( !Utils::Hr::auth($self,'write|admin') );

    my $id = $self->param('payload');
    my $fileid = $self->param('fileid');

	if( $self->req->method  eq 'POST' ){
        if( Utils::Files::update_file($self) ){
    		$self->redirect_to("/hr/files_update/$id?fileid=$fileid");
			return;
		} else {
         	$self->stash( error => 1 );
		}
	}
};

sub files_del{
    my $self = shift;
    return if( !Utils::Hr::auth($self,'write|admin') );

    my $id = $self->param('payload');
    Utils::Files::del_file($self);
    $self->redirect_to("/hr/files/$id");
};

sub files_add_new{
    my $self = shift;
    return if( !Utils::Hr::auth($self,'write|admin') );

    my $id = $self->param('payload');

	if( $self->req->method  eq 'POST' ){
        if( $self->req->error ){
            $self->stash( error => 1 );
            return;
        }
        if( Utils::Files::add_new($self) ){
           	$self->redirect_to("/hr/files/$id");
            return;
		} else {
         	$self->stash( error => 1 );
		}
	}

    Utils::Db::cdb_deploy($self,$id);
};
sub files{
    my $self = shift;
    return if( !Utils::Hr::auth($self,'write|admin') );

    my $id = $self->param('payload');
    $self->stash(files=>Utils::Files::file_list4id($self,$id));
    Utils::Db::cdb_deploy($self,$id);
};

sub move{
    my $self = shift;
    return if( !Utils::Hr::auth($self,'write|admin') );

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
    $self->stash( resources_root => Utils::Hr::get_root_objects($self) );
    # final action
    Utils::Db::cdb_deploy($self,$id);
};

sub make_root{
	my $self = shift;
	my $id   = $self->param('payload');
    my $dbc = Utils::Db::client($self);
	$dbc->child_make_root($id);
    $self->redirect_to("/hr/move/$id");
};

sub calculations{
    my $self = shift;
    my $id = $self->param('payload');
    Utils::Db::cdb_deploy($self,$id);
    $self->stash( calculations => Utils::Db::cdb_get_objects($self,{name=>['calculation']}));
};

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
