package Buh1::Catalog; {

=encoding utf8

=head1 NAME

    Accounts controller

=cut

use Mojo::Base 'Mojolicious::Controller';
use Utils::Catalog ;
use Utils::Files ;
use Data::Dumper ;

sub add{
    my $self = shift;
    return if( !Utils::Catalog::auth($self,'write|admin') );
    my $method = $self->req->method;
    if ( $method =~ /POST/ ){
        my $data = Utils::Catalog::form2data($self);
        if( Utils::Catalog::validate($self,$data) ){
            Utils::Catalog::insert_or_update($self,$data);
            $self->redirect_to('/catalog/list');
        }
	}
};

sub list{
    my $self = shift;
    return if( !Utils::Catalog::auth($self,'read|write|admin') );

    $self->stash( resources_root => Utils::Catalog::get_resources_root($self) );
};

sub edit{
    my $self = shift;
    return if( !Utils::Catalog::auth($self,'write|admin') );
    
    my $method = $self->req->method ;
    if( $method eq 'POST' ){
        my $data = Utils::Catalog::form2data($self);
        Utils::Catalog::insert_or_update($self,$data);
    }
    # final action
    my $id = $self->param('payload');
    Utils::Catalog::deploy($self,$id);
    $self->stash( resources_root => Utils::Catalog::get_resources_root($self) );
};

sub del{
    my $self = shift;
    return if( !Utils::Catalog::auth($self,'write|admin') );

    my $method = $self->req->method ;
    my $id = $self->param('payload');
    if( uc($method) eq 'POST' ){
        Utils::Catalog::del($self,$id);
        $self->redirect_to('/catalog/list');
    }
    # final action
    Utils::Catalog::deploy($self,$id);
};

sub files_update{
    my $self = shift;
    return if( !Utils::Catalog::auth($self,'write|admin') );

    my $id = $self->param('payload');
    my $file = $self->param('file');

    Utils::Catalog::deploy($self,$id);
    Utils::Files::deploy($self,$id,$file);
};

sub files_update_desc{
    my $self = shift;
    return if( !Utils::Catalog::auth($self,'write|admin') );

    my $id = $self->param('payload');
    my $file = $self->param('file');

	if( $self->req->method  eq 'POST' ){
        Utils::Files::update_desc($self);
	}
    $self->redirect_to("/catalog/files_update/$id?file=$file");
};

sub files_update_file{
    my $self = shift;
    return if( !Utils::Catalog::auth($self,'write|admin') );

    my $id = $self->param('payload');
    my $file = $self->param('file');

	if( $self->req->method  eq 'POST' ){
        if( Utils::Files::update_file($self) ){
    		$self->redirect_to("/catalog/files_update/$id?file=$file");
			return;
		} else {
         	$self->stash( error => 1 );
		}
	}
};

sub files_del{
    my $self = shift;
    return if( !Utils::Catalog::auth($self,'write|admin') );

    my $id = $self->param('payload');
    Utils::Files::del_file($self);
    $self->redirect_to("/catalog/files/$id");
};

sub files_add_new{
    my $self = shift;
    return if( !Utils::Catalog::auth($self,'write|admin') );

    my $id = $self->param('payload');

	if( $self->req->method  eq 'POST' ){
        if( Utils::Files::add_new($self) ){
           	$self->redirect_to("/catalog/files/$id");
            return;
		} else {
         	$self->stash( error => 1 );
		}
	}

    Utils::Catalog::deploy($self,$id);
};
sub files{
    my $self = shift;
    return if( !Utils::Catalog::auth($self,'write|admin') );

    my $id         = $self->param('payload');
    my $company_id = $self->session('company id') ;

    $self->stash(files=>Utils::Files::file_list4id($company_id,$id));

    Utils::Catalog::deploy($self,$id);
};

sub move{
    my $self = shift;
    return if( !Utils::Catalog::auth($self,'write|admin') );

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
    $self->stash( resources_root => Utils::Catalog::get_resources_root($self) );
    # final action
    Utils::Catalog::deploy($self,$id);
};

sub make_root{
	my $self = shift;
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
