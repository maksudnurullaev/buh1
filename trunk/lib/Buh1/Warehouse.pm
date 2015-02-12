package Buh1::Warehouse; {

=encoding utf8

=head1 NAME

    Warehouse controller

=cut

use Mojo::Base 'Mojolicious::Controller';
use Encode qw( encode decode_utf8 );
use Utils::Warehouse ;
use Utils::Filter ;
use Utils::Tags ;
use Data::Dumper ;

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

sub export_current{
    my $self = shift;
    return if !$self->who_is('local','reader');
    my $objects = Utils::Warehouse::current_list_objects($self);
    # 1. Get all tags
    for my $pid (keys %{$objects}){
        my $tags = 
            Utils::Db::cdb_get_links($self, 
                $pid, 
                Utils::Warehouse::tag_object_name(), 
                ['name','value'] );
        for my $tagid (keys %{$tags}){
            $objects->{$pid}{tags} = {} if !exists $objects->{$pid}{tags} ;
            $objects->{$pid}{tags}{$tags->{$tagid}{name}} = $tags->{$tagid}{value} ;
        }    
            
    }
    # 2. Get all header tags
    my $headers = {};
    for my $pid (keys %{$objects}){
        my $tags  = $objects->{$pid}{tags};
        next if !$tags;
        for my $name (keys %{$tags}){
            if( !exists($headers->{$name}) ) {
                $headers->{$name} = 1 ;
            } else {
                $headers->{$name}++ ;
            }
        }
    }
    $self->stash( objects => $objects ) if scalar(keys(%{$objects}));
    $self->stash( headers => $headers ) if scalar(keys(%{$headers}));
};

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
