package Buh1::Desktop; {
use Mojo::Base 'Mojolicious::Controller';
use Accounts;
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
    $self->stash(companies => $companies);
};

sub accounts{
    my $self = shift;
    return if !$self->is_user;

    my $parts = Accounts::get_all_parts;
    $self->stash( parts => $parts );

    for my $part_id (keys %{$parts}){
        my $sections = Accounts::get_sections($part_id);
        $parts->{$part_id}{sections} = $sections;

        for my $section_id (keys %{$sections}){
            my $accounts = Accounts::get_accounts($section_id);
            $sections->{$section_id}{accounts} = $accounts;
        }
    }
};

1;

};
