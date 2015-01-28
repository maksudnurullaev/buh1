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

    Utils::Warehouse::deploy_list_objects($self);
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
    return if !Utils::Warehouse::validate_id2edit($self);
    return if !$self->who_is('local','reader');
    return if ($self->req->method eq 'POST') &&
               !$self->who_is('local','writer');

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
    Utils::Warehouse::calculate_counting_fields($self);
};

sub remains{
    my $self = shift;
    return if !$self->who_is('local','reader');

    my($parent,$childs) = Utils::Warehouse::calculate_counting_fields($self);
    $self->stash( remains_objects => { childs => $childs, parent => $parent } )
        if $parent ;

};

sub pagesize{
    my $self = shift;
    Utils::Filter::pagesize($self,$OBJECT_NAMES);
    Utils::Warehouse::redirect2list_or_path($self);
};

sub page{
    my $self = shift;
    Utils::Filter::page($self,$OBJECT_NAMES);
    Utils::Warehouse::redirect2list_or_path($self);
};

sub nofilter{
    my $self = shift;
    Utils::Filter::nofilter($self,"$OBJECT_NAMES/filter");
    Utils::Warehouse::redirect2list_or_path($self);
};

sub filter{
    my $self = shift;
    Utils::Filter::filter($self,$OBJECT_NAMES);
    $self->redirect_to("/warehouse/list");
};

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
