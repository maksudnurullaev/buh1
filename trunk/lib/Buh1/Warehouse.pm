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

my $OBJECT_NAME  = 'warehouse object' ;
my $OBJECT_NAMES = 'warehouse objects' ;

sub list{
    my $self = shift ;
    return if !$self->who_is('local','reader');

    Utils::Warehouse::list_deploy($self);
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

sub edit{
    my $self = shift ;
    return if !Utils::Warehouse::validate2edit($self);

    my $id = $self->param('payload') ;
    Utils::Warehouse::add_edit_post($self) if $self->req->method eq 'POST' ;
    Utils::Db::cdb_deploy($self,$id,'object');

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
    redirect2list_or_path($self);
};
# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
