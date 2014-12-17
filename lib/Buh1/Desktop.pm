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
use Utils::Documents;

sub select_company{
    my $self = shift;
    my $cid = $self->param('payload');
    if( $cid ){
        my $db = Db->new($self);
        my $company = $db->get_objects({id => [$cid], field => ['name']});
        deploy_client_company($self,$cid,$company->{$cid}{name}) if $company && $company->{$cid};
    }
    deploy_client_companies($self);
    Utils::Documents::detach($self);
};

sub deploy_client_company{
    my ($self,$company_id,$company_name) = @_ ;
    my $user_id = $self->session->{'user id'} ;
    return if !$user_id || !$company_id ;

    my $db_client = new DbClient($self);
    if( $db_client->is_valid ){
        $self->session->{'company id'} = $company_id;
        $self->session->{'company name'} = $company_name;
        my $db = Db->new($self);
        $self->session->{'company access'} = 
            $db->get_linked_value('access',$user_id,$company_id) ;
    }
};

sub deploy_client_companies{
    my $self = shift;
    my $db = Db->new($self);
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
