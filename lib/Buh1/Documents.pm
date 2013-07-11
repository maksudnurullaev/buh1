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

sub list{
    my $self = shift;
    if( !$self->is_user ){
        $self->redirect_to('/user/login');
        return;
    }

    my $db_client = Utils::Db::get_client_db($self);
    return if  !$db_client;
};

sub add{
    my $self = shift;
    if( !$self->is_user ){
        $self->redirect_to('/user/login');
        return;
    }
};

1;

};

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
