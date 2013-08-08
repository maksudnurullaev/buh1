package Buh1::Desktop; {

=encoding utf8

=head1 NAME

    Authorization utilites 

=cut


use strict;
use warnings;
use utf8;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;
use Utils::Db;
use DbClient;

sub select_company{
    my $self = shift;
    return if !$self->is_user;

    my $cid = $self->param('payload');
    if( $cid ){
        my $db = Db->new();
        my $company = $db->get_objects({id => [$cid], field => ['name']});
        deploy_client_company($self,$cid,$company->{$cid}{name}) if $company && $company->{$cid};
    }
    deploy_client_companies($self);
};

sub deploy_client_company{
    my ($self,$cid,$cname) = @_;

    my $db_client = new DbClient($cid);
    if( $db_client->is_valid ){
        $self->session->{'company id'} = $cid;
        $self->session->{'company name'} = $cname;
    }
};

sub deploy_client_companies{
    my $self = shift;
    my $db = Db->new();
    my $user_id = $self->session('user id');
    my $companies = $db->get_links( $user_id, 'company', ['name'] );

    for my $cid (keys %{$companies}){
       my $company = $db->get_objects({id => [$cid], field => ['name']})->{$cid};
       $companies->{$cid} = {
           name   => $company->{name},
           access => $db->get_linked_value('access',$cid,$user_id)
       };
    }
    $self->stash( companies => $companies ) if scalar keys %{$companies};
};

1;

};

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
