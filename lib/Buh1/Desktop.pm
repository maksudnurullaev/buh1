package Buh1::Desktop; {
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
    warn Dumper($companies);
    $self->stash(user => $user);
    $self->stash(companies => $companies);
};

1;

};
