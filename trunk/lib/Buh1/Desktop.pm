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

sub select_company{
    my $self = shift;
    return if !$self->is_user;

    my $cid = $self->param('payload');
    my $db = Db->new();
    if( $cid ){
        my $company = $db->get_objects({id => [$cid], field => ['name']});
        $self->session->{'company id'} = $cid;
        $self->session->{'company name'} = $company->{$cid}{name};
    }
    my $user = $db->get_user(Utils::User::current($self));
    my $companies = $db->get_links($user->{id}, 'company', ['name']);
    for my $cid(keys %{$companies}){
       my $company = $db->get_objects({id => [$cid], field => ['name']})->{$cid};
       $companies->{$cid} = {
                name   => $company->{name},
                access => $db->get_linked_value('access',$cid,$user->{id})
            };
    }
    $self->stash( user => $user );
    $self->stash( companies => $companies ) if scalar keys %{$companies};
};

1;

};

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
