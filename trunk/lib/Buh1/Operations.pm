package Buh1::Operations; {

=encoding utf8

=head1 NAME

    Operations controller

=cut

use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;
use Utils::Accounts;
use Utils::Documents;
use Utils::Cacher;
use Utils::Operations;

sub list{
    my $self = shift;
    my $data;
    return( $self->stash( parts => $data) ) if $data = is_cached($self,'data');

    # Level 1 - get parts
    $data = Utils::Accounts::get_all_parts($self);
    $self->stash( parts => $data );
    for my $part_id (keys %{$data}){
        # Level 2 - get sections
        my $sections = Utils::Accounts::get_sections($self,$part_id);
        $data->{$part_id}{sections} = $sections;
        for my $section_id (keys %{$sections}){
            # Level 3 - get accounts
            my $accounts = Utils::Accounts::get_accounts($self,$section_id);
            $sections->{$section_id}{accounts} = $accounts;
        }
    }
    Utils::Languages::generate_name($self, $data);

    cache_it($self,'data',$data);
    $self->stash( parts => $data );
};

sub delete_bt{ #delete business transaction
    my $self = shift;
    my $account_id = $self->param('payload');
    my $bt_id      = $self->param('bt');
    if( !$account_id || !$bt_id ){
        $self->redirect_to('/operations/list');
        return;
    }
    my $db = Db->new($self);
    if( $db->del($bt_id) ){
        $db->del_link($account_id,$bt_id);
    }
    clear_cache($self);
    $self->redirect_to("/operations/account/$account_id");
};

sub add{
    my $self = shift;
    my $account_id = $self->param("payload");
    if( !$account_id ){
        $self->redirect_to('/operations/list');
        return;
    }

    my $method = $self->req->method;
    my ($data,$id);
    my $db = Db->new($self);
    if ( $method =~ /POST/ ){
        $data = Utils::Operations::validate( $self );
        if( !exists($data->{error}) ){
            if( $id = $db->insert($data) ){
                $db->set_link(
                    Utils::Operations::get_object_name(),
                    $id,
                    Utils::Accounts::get_account_name(),
                    $account_id);
                clear_cache($self);
                $self->redirect_to("/operations/edit/$account_id?bt=$id");
                return;
            } else {
               $self->stash(error => 1);
               warn "Operations:add:ERROR: could not insert!";
            }
        } else {
            $self->stash(error => 1);
        }
    } 

    my $account = $db->get_objects({id => [$account_id]});
    $db->links_attach(
        $account,
        'bts',
        Utils::Operations::get_object_name(),
        Utils::merge2arr_ref(Utils::Languages::get(),'number','debet','credit'));
    $self->stash( account => $account );
    Utils::Languages::generate_name($self, $account);
};

sub edit{
    my $self = shift;
    my ($account_id,$bt_id, $docid) = ($self->param("payload"),$self->param("bt"),$self->param('docid'));
    Utils::Documents::attach($self,$docid) if $docid ;
    if( !$account_id || !$bt_id ){
        $self->redirect_to('/operations/list');
        return;
    }
    my $db = Db->new($self);
    my $bt = $db->get_objects({id => [$bt_id]});
    my $account = $db->get_objects({id => [$account_id]});
    if ( !$bt || !$account ){
        $self->redirect_to('/operations/list');
        warn "Operations:edit:error some objects are not exists!";
        return;
    }

    my ($method,$data) = ($self->req->method,undef);
    if ( $method =~ /POST/ ){
        $data = Utils::Operations::validate( $self );
        if( !exists($data->{error}) ){
            $data->{id} = $bt_id;
            if( $db->update($data) ){
                $self->stash(success => 1);
                clear_cache($self);
            } else {
                $self->stash(error => 1);
                warn "Operations:edit:ERROR: could not update!";
            }
        } else {
            $self->stash(error => 1);
        }
    } 

    $db->links_attach(
        $account,
        'bts',
        Utils::Operations::get_object_name(),
        Utils::merge2arr_ref(Utils::Languages::get(),'number','debet','credit'));
    Utils::Languages::generate_name($self, $account);
    $self->stash( paccount => $account );

    $bt = $db->get_objects({id => [$bt_id]});
    Utils::Languages::generate_name($self,$bt);
    for my $key (keys %{$bt->{$bt_id}}){
        $self->stash( $key => $bt->{$bt_id}{$key} );
    }
    my ($debets,$credits) = (
        Utils::Accounts::get_account_by_numeric_id($self,$bt->{$bt_id}{debet}),
        Utils::Accounts::get_account_by_numeric_id($self,$bt->{$bt_id}{credit})
        );
    Utils::Languages::generate_name($self,$debets);
    $self->stash( debets  => $debets );
    Utils::Languages::generate_name($self,$credits);
    $self->stash( credits => $credits );
};

sub account{
    my $self = shift;
    my $account_id = $self->param("payload");
    if( !$account_id ){
        $self->redirect_to('/operations/list');
        return;
    }

    my $db = Db->new($self);
    my $account = $db->get_objects({id => [$account_id]});
    $self->stash( account => $account );
    $db->links_attach(
        $account,
        'bts',
        Utils::Operations::get_object_name(),
        Utils::merge2arr_ref(Utils::Languages::get(),'number','debet','credit'));
    Utils::Languages::generate_name($self,$account);
};

# END OF PACKAGE

};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
