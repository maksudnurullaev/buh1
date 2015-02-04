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
    Utils::Calculcation::add($self) if $self->req->method =~ /POST/; 
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

    my $id = $self->param('payload');
    my $method = $self->req->method;
    if( $method =~ /POST/ ){
        return if !Utils::Calculations::authorized2edit($self) ;

        my $data = Utils::Calculations::form2data($self);
        if( Utils::Calculations::validate($self,$data) ){
            if( defined $self->param('make_copy') ){
                my $dbc = Utils::Db::main($self);
                my $template = $dbc->get_objects({ id => [$id] })->{$id} ;
                delete $data->{id} ;
                delete $template->{id} ;
                delete $template->{description} ;
                for my $key (keys %{$template}){
                    $data->{$key} = $template->{$key} if $key !~ /^_/ ;
                }
                my $new_id = $dbc->insert($data);
                $self->redirect_to("/calculations/edit/$new_id");
                return;
            } else {
                Utils::Db::db_insert_or_update($self,$data);
                $self->stash(success => 1);
            }
        }
    }
    my $data = Utils::Db::db_deploy($self,$id) ;
    Utils::Calculations::deploy_result($self, $data) ;
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
