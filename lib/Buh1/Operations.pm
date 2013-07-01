package Buh1::Operations; {

=encoding utf8

=head1 NAME

    Operations controller

=cut

use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;
use Utils::Accounts;

my $OBJECT_NAME = 'business transaction';

sub list{
    my $self = shift;
    if ( !$self->is_editor ){
        $self->redirect_to('/user/login');
        return;
    }

    my $data = Utils::Accounts::get_all_parts();
    $self->stash( parts => $data );

    for my $part_id (keys %{$data}){
        my $sections = Utils::Accounts::get_sections($part_id);
        $data->{$part_id}{sections} = $sections;

        for my $section_id (keys %{$sections}){
            my $accounts = Utils::Accounts::get_accounts($section_id);
            $sections->{$section_id}{accounts} = $accounts;
        }
    }
    ml($self, $data);
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
    if ( !$self->is_admin ){
        $self->redirect_to('/user/login');
        return;
    }
    my $account_id = $self->param('payload');
    my $bt_id      = $self->param('bt');
    if( !$account_id || !$bt_id ){
        $self->redirect_to('/operations/list');
        return;
    }
    if( Db::del($bt_id) ){
        Db::del_link($account_id,$bt_id);
    }
    $self->redirect_to("/operations/account/$account_id");
};

sub add{
    my $self = shift;
    if ( !$self->is_editor ){
        $self->redirect_to('/user/login');
        return;
    }

    my $account_id = $self->param("payload");
    if( !$account_id ){
        $self->redirect_to('/operations/list');
        return;
    }

    my $method = $self->req->method;
    my ($data,$id);
    if ( $method =~ /POST/ ){
        $data = validate( $self );
        if( !exists($data->{error}) ){
            if( $id = Db::insert($data) ){
                Db::set_link(
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

    my $account = Db::get_objects({id => [$account_id]});
    Db::attach_links($account,'bts',$OBJECT_NAME,['rus','eng','uzb','number','debet','credit']);
    $self->stash( account => $account );
    ml($self, $account);
};

sub edit{
    my $self = shift;
    if ( !$self->is_editor ){
        $self->redirect_to('/user/login');
        return;
    }

    my ($parent_account_id,$bt_id) = ($self->param("payload"),$self->param("bt"));
    if( !$parent_account_id || !$bt_id ){
        $self->redirect_to('/operations/list');
        return;
    }
    my $bt = Db::get_objects({id => [$bt_id]});
    my $parent_account = Db::get_objects({id => [$parent_account_id]});
    if ( !$bt || !$parent_account ){
        $self->redirect_to('/operations/list');
        warn "Operations:edit:error some objects are not exists!";
        return;
    }

    my ($method,$data) = ($self->req->method,undef);
    if ( $method =~ /POST/ ){
        $data = validate( $self );
        if( !exists($data->{error}) ){
            $data->{id} = $bt_id;
            if( Db::update($data) ){
               $self->stash(success => 1);
            } else {
               $self->stash(error => 1);
               warn "Operations:edit:ERROR: could not update!";
            }
        } else {
            $self->stash(error => 1);
        }
    } 

    $parent_account = Db::get_objects({
        id    => [$parent_account_id], 
        field => Utils::Languages::get()});
    Db::attach_links($parent_account,'bts',$OBJECT_NAME,['rus','eng','uzb','number','debet','credit']);
    ml($self, $parent_account);
    $self->stash( parent_account => $parent_account );

    $bt = Db::get_objects({id => [$bt_id]});
    ml($self,$bt);
    for my $key (keys %{$bt->{$bt_id}}){
        $self->stash( $key => $bt->{$bt_id}{$key} );
    }
    my ($debets,$credits) = (
        Utils::Accounts::get_account_by_numeric_id($bt->{$bt_id}{debet}),
        Utils::Accounts::get_account_by_numeric_id($bt->{$bt_id}{credit})
        );
    ml($self,$debets);
    $self->stash( debets  => $debets );
    ml($self,$credits);
    $self->stash( credits => $credits );
};

sub ml{
    my ($self,$hash) = @_;
    Utils::Accounts::normalize_local(
        $hash,
        Utils::Languages::get(),
        Utils::Languages::current($self));
};

sub account{
    my $self = shift;
    if ( !$self->is_editor ){
        $self->redirect_to('/user/login');
        return;
    }

    my $account_id = $self->param("payload");
    if( !$account_id ){
        $self->redirect_to('/operations/list');
        return;
    }

    my $account = Db::get_objects({id => [$account_id]});
    $self->stash( account => $account );
    Db::attach_links($account,'bts',$OBJECT_NAME,['rus','eng','uzb','number','debet','credit']);
    Utils::Accounts::normalize_local(
        $account,
        Utils::Languages::get(),
        Utils::Languages::current($self));
};

# END OF PACKAGE

};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
