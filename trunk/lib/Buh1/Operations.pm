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

my $OBJECT_NAME = 'business transaction';

sub list{
    my $self = shift;

    my $data;
    $self->stash( parts => $data );
    if( $data = is_cached($self,'data') ) {
        warn 'USED CACHED VERSION OF DATA';
    } else {
        $data = Utils::Accounts::get_all_parts($self);
        $self->stash( parts => $data );

        for my $part_id (keys %{$data}){
            my $sections = Utils::Accounts::get_sections($self,$part_id);
            $data->{$part_id}{sections} = $sections;

            for my $section_id (keys %{$sections}){
                my $accounts = Utils::Accounts::get_accounts($self,$section_id);
                $sections->{$section_id}{accounts} = $accounts;
            }
        }
        $self->cache->{data} = $data;
        Utils::Languages::generate_name($self, $data);
        cache_it($self,'data',$data);
    }
};

sub validate{
    my $self = shift;
    my $edit_mode = shift;
    my $data = { 
        object_name => $OBJECT_NAME,
        account => $self->param('account'),
        updater => Utils::User::current($self) };
    my @fields4rule1 = ('number','rus','credit','debet');
    for my $field (@fields4rule1){
        $data->{$field} = Utils::trim $self->param($field);
        if ( !$data->{$field} ){
            $data->{error} = 1; 
            $self->stash(($field . '_class') => 'error');
        }
    }
    if( $data->{number} !~ /^[1-9][0-9]*\.?[0-9]*$/ ){
        $data->{error} = 1;
         $self->stash('number_class' => 'error');
    }
    my @fields4rule2 = ('credit','debet');
    for my $field (@fields4rule2){
        if( $data->{$field} !~ /^\d+[\d+|\d+,|\d+-]+$/ ){
            $data->{error} = 1;
            $self->stash(($field . '_class') => 'error');
        }
    }
    my @optional_fields = ('eng','uzb');
    for my $field (@optional_fields){
        $data->{$field} = Utils::trim $self->param($field) 
            if Utils::trim $self->param($field);
    }
    return($data);
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
        $data = validate( $self );
        if( !exists($data->{error}) ){
            if( $id = $db->insert($data) ){
                $db->set_link(
                    $OBJECT_NAME,
                    $id,
                    Utils::Accounts::get_account_name(),
                    $account_id);
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
    $db->links_attach($account,'bts',$OBJECT_NAME,['rus','eng','uzb','number','debet','credit']);
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
        $data = validate( $self );
        if( !exists($data->{error}) ){
            $data->{id} = $bt_id;
            if( $db->update($data) ){
               $self->stash(success => 1);
            } else {
               $self->stash(error => 1);
               warn "Operations:edit:ERROR: could not update!";
            }
        } else {
            $self->stash(error => 1);
        }
    } 

    $db->links_attach($account,'bts',$OBJECT_NAME,['rus','eng','uzb','number','debet','credit']);
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
        $OBJECT_NAME,
        ['rus','eng','uzb','number','debet','credit']);
    Utils::Languages::generate_name($self,$account);
};

# END OF PACKAGE

};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
