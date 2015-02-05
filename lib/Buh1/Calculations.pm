package Buh1::Calculations; {

=encoding utf8

=head1 NAME

    Accounts controller

=cut

use Mojo::Base 'Mojolicious::Controller' ;
use Utils::Calculations ;
use Utils::Db ;

sub page{
    my $self = shift;
    $self->stash( calculations => Utils::Calculations::get_db_list($self));
};

sub add{
    my $self = shift;
    Utils::Calculations::add($self) if $self->req->method =~ /POST/; 
};

sub test{
    my $self = shift;
    my $id = $self->param('payload');
    my $method = $self->req->method;
    my $data = {} ;
    
    if ( $method =~ /POST/ ){
        my @param = $self->param ;
        for my $key (@param){
            $data->{$key} = $self->param($key);
            $self->stash( $key => $self->param($key) ) ;
        }
    } else {
        $data = Utils::Db::db_deploy($self,$id) ;
        if( !$data ){
            $self->redirect_to('/calculations/page');
            return ;
        }
    }
    Utils::Calculations::deploy_result($self, $data) ;
};

sub edit{
    my $self = shift;
    Utils::Calculations::edit($self) if $self->req->method =~ /POST/; 
};

sub delete{
    my $self = shift;
    my $id = $self->param('payload') ;
	my $db = Utils::Db::main($self) ;
	$db->del($id);
	$self->redirect_to("/calculations/page");
};

sub update_fields{
    my $self = shift;
    my $id = $self->param('payload');
    my $method = $self->req->method;
    if ( $method =~ /POST/ ){
        my $data = Utils::Calculations::form2data_fields($self);
        # delete all old definitions
        Utils::Db::db_execute_sql($self, " delete from objects where id = '$id' and field like 'f_%' ; " ) ;
        # insert new ones
        Utils::Db::db_insert_or_update($self,$data);
        $self->stash(success => 1);
    }
    $self->redirect_to("/calculations/edit/$id");
};

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
