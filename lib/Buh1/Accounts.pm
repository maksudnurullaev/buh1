package Buh1::Accounts; {

=encoding utf8

=head1 NAME

    Accounts controller

=cut

use Mojo::Base 'Mojolicious::Controller';
use Utils::Accounts;
use Data::Dumper;

sub list{
    my $self = shift;
    return if !$self->is_admin;

    my $parts = Utils::Accounts::get_all_parts;
    $self->stash( parts => $parts );

    for my $part_id (keys %{$parts}){
        my $sections = Utils::Accounts::get_sections($part_id);
        $parts->{$part_id}{sections} = $sections;

        for my $section_id (keys %{$sections}){
            my $accounts = Utils::Accounts::get_accounts($section_id);
            $sections->{$section_id}{accounts} = $accounts;
            for my $account_id (keys %{$accounts}){
                my $account = $sections->{$section_id}{accounts}{$account_id};
                $account->{subcontos} = Utils::Accounts::get_subcontos($account_id);
            }
        }
    }
};

sub validate4update{
    my $self = shift;
    my $edit_mode = shift;
    my $data = { 
        object_name => $self->param('object_name'),
        updater => Utils::User::current($self) };
    my @languages = ('rus','eng','uzb');
    for my $language (@languages){
        $data->{$language} = Utils::trim $self->param($language);
        $data->{error} = 1 if !$data->{$language};
    }
    $data->{type} = $self->param('type') if $self->param('type');
    return($data);
};
sub edit{
    my $self = shift;
    return if !$self->is_admin;

#    $self->stash(edit_mode => 1);
    my $method = $self->req->method;
    my $data;
    my $id = $self->param('payload');
    if( !$id ) { 
        $self->redirect_to('/accounts/list'); 
        warn "Accounts:edit:error id not defined!";
        return; 
    }
    if ( $method =~ /POST/ ){
        $data = validate4update( $self );
        if( !exists($data->{error}) ){
            $data->{id} = $id;
            if( Db::update($data) ){
                $self->stash(success => 1);
            } else {
                $self->stash(error => 1);
                warn 'Accounts:edit:ERROR: could not update!';
            }
        } else {
            $self->stash(error => 1);
        }
    } 
    $data = Db::get_objects({id=>[$id]});
    my $parent_name = Utils::Accounts::get_parent_name($data->{$id}{object_name});
    my $child_name  = Utils::Accounts::get_child_name($data->{$id}{object_name});
    Db::attach_links($data,'PARENTS',$parent_name,['rus','eng','uzb']) if $parent_name;
    Db::attach_links($data,'CHILDS' ,$child_name,['rus','eng','uzb']) if $child_name;
    if( $data ){
        for my $key (keys %{$data->{$id}} ){
            warn $key;
            $self->stash($key => $data->{$id}->{$key});
        }
        $self->stash(types => Utils::Accounts::get_types4select($self,$data->{$id}{type})) if exists $data->{$id}{type};
    } else {
        redirect_to('/accounts/list');
    }
};


# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
