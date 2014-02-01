package Buh1::Hr; {

=encoding utf8

=head1 NAME

    Accounts controller

=cut

use Mojo::Base 'Mojolicious::Controller';
use Utils::Hr ;
use Data::Dumper ;

sub add{
    my $self = shift;
    return if( !Utils::Hr::auth($self,'write|admin') );
    my $method = $self->req->method;
    if ( $method =~ /POST/ ){
        my $data = Utils::Hr::form2data($self);
        if( Utils::Hr::validate($self,$data) ){
            Utils::Hr::insert_or_update($self,$data);
            $self->redirect_to('/hr/list');
        }
	}
};

sub list{
    my $self = shift;
    return if( !Utils::Hr::auth($self,'read|write|admin') );

    $self->stash( resources_root => Utils::Hr::get_resources_root($self) );
};

sub edit{
    my $self = shift;
    return if( !Utils::Hr::auth($self,'write|admin') );
    
    my $method = $self->req->method ;
    if( $method eq 'POST' ){
        my $data = Utils::Hr::form2data($self);
        Utils::Hr::insert_or_update($self,$data);
    }
    # final action
    my $id = $self->param('payload');
    Utils::Hr::deploy($self,$id);
    $self->stash( resources_root => Utils::Hr::get_resources_root($self) );
};

sub del{
    my $self = shift;
    return if( !Utils::Hr::auth($self,'write|admin') );

    my $method = $self->req->method ;
    my $id = $self->param('payload');
    if( uc($method) eq 'POST' ){
        Utils::Hr::del($self,$id);
        $self->redirect_to('/hr/list');
    }
    # final action
    Utils::Hr::deploy($self,$id);
};

sub files{
    my $self = shift;
    return if( !Utils::Hr::auth($self,'write|admin') );

    my $method = $self->req->method ;
    my $id = $self->param('payload');

	if( $method eq 'POST' ){
		if( $self->req->is_limit_exceeded ){
            $self->stash( error => 1 );
			return ;
		}
		my $new_file = $self->param('new_file');
		if( $new_file->size ){
			warn $new_file->filename ;
			#TODO Utils::Files:new_file4id($new_file,$id);
		}
	}

    Utils::Hr::deploy($self,$id);
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
    $self->stash( resources_root => Utils::Hr::get_resources_root($self) );
    # final action
    Utils::Hr::deploy($self,$id);
};

sub make_root{
	my $self = shift;
	my $id   = $self->param('payload');
    my $dbc = Utils::Db::client($self);
	$dbc->child_make_root($id);
    $self->redirect_to("/hr/move/$id");
};


# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
