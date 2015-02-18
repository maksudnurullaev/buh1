package Buh1::Warehouse; {

=encoding utf8

=head1 NAME

    Warehouse controller

=cut

use Mojo::Base 'Mojolicious::Controller' ;
use Encode qw( encode decode_utf8 ) ;
use Utils::Warehouse ;
use Utils::Filter ;
use Utils::Tags ;
use Utils::Excel ;
use Data::Dumper ;
use Utils::Files ;

my $OBJECT_NAME  = 'warehouse object' ;
my $OBJECT_NAMES = 'warehouse objects' ;

sub list{
    my $self = shift ;
    return if !$self->who_is('local','reader');
    my $objects = Utils::Warehouse::current_list_objects($self);
    $self->stash( objects => $objects ) if scalar(keys(%{$objects}));
};

sub add{
    my $self = shift ;
    return if !$self->who_is('local','writer');

    Utils::Warehouse::add_edit_post($self) if $self->req->method eq 'POST' ;
};

sub add_tag{
    my $self = shift ;
    return if !$self->who_is('local','writer');
    my $pid = $self->param('payload') ;
    my $result1 = Utils::Tags::add($self);
    my $result2 = Utils::Tags::add2($self);

    $self->redirect_to("/warehouse/edit/$pid?" . (($result1 || $result2) ? "success=1" : "error=1" )) ;
};

sub update_tag{
    my $self = shift ;
    return if !$self->who_is('local','writer');
    my $pid = $self->param('payload') ;
    my $tagid = $self->param('tagid') ;
    my $result = Utils::Tags::update($self);

    $self->redirect_to("/warehouse/edit/$pid?tagid=$tagid&" . ($result ? "success=1" : "error=1" )) ;
};

sub del_tag{
    my $self = shift ;
    return if !$self->who_is('local','writer');
    my $pid = $self->param('payload') ;
    my $tagid = $self->param('tagid') ;
    my $result = Utils::Tags::del($self);
    
    if( $result ){
        $self->redirect_to("/warehouse/edit/$pid?success=1" ) ;
    } else {
        $self->redirect_to("/warehouse/edit/$pid?tagid=$tagid&error=1" ) ;
    }
};

sub update_counting_field{
    my $self = shift ;
    return if !$self->who_is('local','writer');
    my $pid = $self->param('payload') ;
    Utils::Warehouse::update_counting_field($self);
};

sub edit{
    my $self = shift ;
    return if !$self->who_is('local','reader');
    return if ($self->req->method eq 'POST') &&
               !$self->who_is('local','writer');
    return if !Utils::Warehouse::validate_id2edit($self);

    my $id = $self->param('payload') ;
    if( $self->param('make_clone') ){
        Utils::Warehouse::clone_object($self) if $self->req->method eq 'POST' ;
    } else {
        Utils::Warehouse::add_edit_post($self) if $self->req->method eq 'POST' ;
    }
    Utils::Db::cdb_deploy($self,$id,'object');
    if( my $tagid = $self->param('tagid') ){
        Utils::Db::cdb_deploy($self,$tagid,'tag');
    }
    my($parent,$childs,$caclulated_counting) 
        = Utils::Warehouse::calculated_counting($self,$id);
    $self->stash(calculated_counting => $caclulated_counting);
};

sub remains{
    my $self = shift;
    return if !$self->who_is('local','reader');

    my $id = $self->param('payload') ;
    my($parent,$childs,$caclulated_counting) 
        = Utils::Warehouse::calculated_counting($self,$id);
    $self->stash(calculated_counting => $caclulated_counting);
    $self->stash(remains_objects => {childs => $childs, parent => $parent}) if $parent;
};

sub remains_all{
    my $self = shift;
    return if !$self->who_is('local','reader');

    Utils::Warehouse::deploy_remains_all($self);
};

sub export{
    my $self = shift ;
    return if !$self->who_is('local','reader');

    my ($scope,$type) = ($self->param('scope'),$self->param('type'));
    my ($file_path,$file_name,$objects,$headers) =
        Utils::Excel::warehouse_export($self,$scope,$type);    
    if($file_path && $file_name){
        $self->render_file( filepath => $file_path, filename => $file_name );
    } else {
        $self->stash( headers => $headers );
        $self->stash( objects => $objects );
    }
};

sub export_remains{
    my $self = shift ;
    return if !$self->who_is('local','reader');

    my $pid = $self->param('payload');
    my $type = $self->param('type');
    my ($file_path,$file_name) =
        Utils::Excel::warehouse_export_remains($self,$type,[$pid]);    
    if($file_path && $file_name){
        $self->render_file( filepath => $file_path, filename => $file_name );
    } else {
        $self->redirect_to("/warehouse/remains/$pid?error=1");
    }
};

sub export_remains_all{
    my $self = shift ;
    return if !$self->who_is('local','reader');

    my ($scope,$type) = ($self->param('scope'),$self->param('type'));
    my $rids =  $scope eq 'current' ?
                Utils::Warehouse::get_remains_ids($self): 
                Utils::Warehouse::get_remains_ids_all($self);
    my ($file_path,$file_name) =
        Utils::Excel::warehouse_export_remains($self,$type,$rids);    
    if($file_path && $file_name){
        $self->render_file( filepath => $file_path, filename => $file_name );
    } else {
        $self->redirect_to("/warehouse/remains_all?error=1");
    }
};

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
