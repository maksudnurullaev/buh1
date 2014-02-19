package Buh1::Templates; {

=encoding utf8

=head1 NAME

    Accounts controller

=cut

use Mojo::Base 'Mojolicious::Controller';
use Utils::Templates ;
use Utils::Files ;
use Data::Dumper ;

sub add{
    my $self = shift;
    return if !$self->is_admin();

    my $method = $self->req->method;
    if ( $method =~ /POST/ ){
        my $data = Utils::Templates::form2data($self);
        if( Utils::Templates::validate($self,$data) ){
            Utils::Db::db_insert_or_update($self,$data);
            $self->stash(success => 1);
            $self->redirect_to('/templates/list');
        }
	}
};

sub list{
    my $self = shift;
    $self->stash( resources_root => Utils::Templates::get_root_objects($self) );
};

sub edit{
    my $self = shift;
    my $id   = $self->param('payload');
    if( !$self->is_admin() ){
        $self->redirect_to("templates/files/$id");
        return;
    }
    
    my $method = $self->req->method ;
    if( $method eq 'POST' ){
        my $data = Utils::Templates::form2data($self);
        $self->stash(success => 1);
        Utils::Db::db_insert_or_update($self,$data);
    }
    # final action
    Utils::Db::db_deploy($self,$id);
    $self->stash( resources_root => Utils::Templates::get_root_objects($self) );
};

sub del{
    my $self = shift;
    return if !$self->is_admin();

    my $method = $self->req->method ;
    my $id = $self->param('payload');
    if( uc($method) eq 'POST' ){
        my $dbc = Utils::Db::main() ;
        $dbc->del($id);
        $self->redirect_to('/templates/list');
    }
    # final action
    Utils::Db::db_deploy($self,$id);
};

sub files_update{
    my $self = shift;
    # return if !$self->is_admin();

    my $id = $self->param('payload');
    my $fileid = $self->param('fileid');

    warn Dumper Utils::Db::db_deploy($self,$id,'template');
    Utils::Files::deploy($self,$id,$fileid);
};

sub files_update_desc{
    my $self = shift;
    return if !$self->is_admin();

    my $id = $self->param('payload');
    my $fileid = $self->param('fileid');

	if( $self->req->method  eq 'POST' ){
        Utils::Files::update_desc($self);
	}
    $self->redirect_to("/templates/files_update/$id?fileid=$fileid");
};

sub files_update_file{
    my $self = shift;
    return if !$self->is_admin();

    my $id = $self->param('payload');
    my $fileid = $self->param('fileid');

	if( $self->req->method  eq 'POST' ){
        if( Utils::Files::update_file($self) ){
    		$self->redirect_to("/templates/files_update/$id?fileid=$fileid");
			return;
		} else {
         	$self->stash( error => 1 );
		}
	}
}
;

sub files_del{
    my $self = shift;
    return if !$self->is_admin();

    my $id = $self->param('payload');
    Utils::Files::del_file($self);
    $self->redirect_to("/templates/files/$id");
};

sub files_add_new{
    my $self = shift;
    return if !$self->is_admin();

    my $id = $self->param('payload');

	if( $self->req->method  eq 'POST' ){
        if( $self->req->error ){
            $self->stash( error => 1 );
            return;
        }
        if( Utils::Files::add_new($self) ){
           	$self->redirect_to("/templates/files/$id");
            return;
		} else {
         	$self->stash( error => 1 );
		}
	}

    Utils::Db::db_deploy($self,$id);
};
sub files{
    my $self = shift;

    my $id         = $self->param('payload');

    $self->stash(files=>Utils::Files::file_list4id($self,$id));

    Utils::Db::db_deploy($self,$id);
};

sub move{
    my $self = shift;
    return if !$self->is_admin();

    my $method = $self->req->method ;
    my $id = $self->param('payload');

    if( $method eq 'POST' ){
        my $new_parent = $self->param('new_parent');
        my $parent = $self->param('parent');
		
        if( !$new_parent || ($parent && $parent eq $new_parent) ){
            $self->stash( error => 1 );
        } else {
            my $dbc = Utils::Db::main();
            $dbc->child_set_parent($id,$new_parent);
        }
    }
    $self->stash( resources_root => Utils::Templates::get_root_objects($self) );
    # final action
    Utils::Db::db_deploy($self,$id);
};

sub make_root{
	my $self = shift;
    return if !$self->is_admin();

	my $id   = $self->param('payload');
    my $dbc = Utils::Db::main();
	$dbc->child_make_root($id);
    $self->redirect_to("/templates/move/$id");
};


# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
