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

sub select_company{
    my $self = shift;
    return if !$self->is_user;

    my $cid = $self->param('payload');
    if( $cid ){
        my $company = Db::get_objects({id => [$cid], field => ['name']});
        $self->session->{'company id'} = $cid;
        $self->session->{'company name'} = $company->{$cid}{name};
    }
    my $user = Db::get_user Utils::User::current($self);
    my $companies = Db::get_links($user->{id}, 'company', ['name']);
    for my $cid(keys %{$companies}){
       my $company = Db::get_objects({id => [$cid], field => ['name']})->{$cid};
       $companies->{$cid} = {
                name   => $company->{name},
                access => Db::get_linked_value('access',$cid,$user->{id})
            };
    }
    $self->stash(user => $user);
    $self->stash(companies => $companies) if scalar keys %{$companies};
};


1;

};

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut