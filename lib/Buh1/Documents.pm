package Buh1::Documents; {

=encoding utf8

=head1 NAME

    Documents

=cut


use strict;
use warnings;
use utf8;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;
use Utils::Db;

my $OBJECT_NAME         = 'document';
my $OBJECT_NAMES        = 'documents';

sub valid_user{
    my $self = shift;
    if( !$self->is_user ){
        $self->redirect_to('/user/login');
        return;
    }
    return(1);
};

sub link_accounts_and_bt{
    my $self = shift;
    my $parameters = {
        account => $self->param("payload"),
        bt => $self->param("bt"),
        debet => $self->param("DEBET"),
        credit => $self->param("CREDIT"),
        };
    my $db = Db->new();
    for my $key (keys %{$parameters}){
        my $id = $parameters->{$key};
        if( !$id ){
            warn "No ID to linked object($key) defined!";
            $self->stash( error => 1 );
            return;
        }
        my $db_object = $db->get_objects({id => [$id]});
        if( !$db_object ){
            warn "No db object($id) found in database!";
            $self->stash( error => 1 );
            return;
        }
        Utils::Languages::generate_name($self,$db_object);
        $self->stash( $key => $db_object->{$id} );
    }
    return(1)   
};

sub list{
    my $self = shift;
    return if !valid_user($self);

    my $db_client = Utils::Db::get_client_db($self);
    return if !$db_client;
};

sub add{
    my $self = shift;
    return if !valid_user($self);
    return if !link_accounts_and_bt($self);
};

1;

};

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
