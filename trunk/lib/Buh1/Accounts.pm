package Buh1::Accounts; {

=encoding utf8

=head1 NAME

    Accounts controller

=cut

use Mojo::Base 'Mojolicious::Controller';
use Utils::Accounts;
use Data::Dumper;

sub access{
    my $self = shift;
    if ( !$self->is_editor ){
        $self->redirect_to('/user/login');
        return(undef);
    }
    return(1);
};

sub add_part{
    my $self = shift;
    return if !access($self);

    my $method = $self->req->method;
    my ($data,$id);
    # 1. Test for payload - parents account!
    my $parent_id = $self->param('payload');
    my ($parents, $object_name4form);
    my $db = Db->new();
    if ( $parent_id ){
        $parents = $db->get_objects({id=>[$parent_id]});
        if( !$parents ){
            warn "Accounts:add_part: no parents! Redirecting...";
            $self->redirect_to('/accounts/list');
            return;
        }
        $object_name4form = Utils::Accounts::get_child_name_by_id($parent_id)
            || Utils::Account::get_part_name();
    } else {
        $object_name4form = Utils::Accounts::get_part_name();
    }
    $self->stash( object_name => $object_name4form );
    # 2. Process post if needs
    if ( $method =~ /POST/ ){
        $data = validate4add_part($self);
        if( !exists($data->{error}) ){
            my $object_name = $data->{object_name};
            # set new id
            $data->{id} = "$object_name $data->{id}";
            if( $id = $db->insert($data) ){
                warn $db->set_link(
                    $parents->{$parent_id}{object_name},
                    $parent_id,
                    $object_name,
                    $id) if $parents ;
                $self->redirect_to("/accounts/edit/$id");
                return;
            } else {
                $self->stash(error => 1);
                warn 'Accounts:edit:ERROR: could not update!';
            }
        } else {
            $self->stash( error => 1 );
        }
    } 
    $data = $db->get_objects({id=>[$id]});
    $self->stash( types => 
           Utils::Accounts::get_types4select($self)
        ) if $object_name4form eq Utils::Accounts::get_account_name();
    if( $data ){
        $data->{PARENTS} = $parents->{$parent_id} if $parents;
        generate_name($self,$data);
        for my $key (keys %{$data->{$id}} ){
            $self->stash($key => $data->{$id}->{$key});
        }
    } else {
        generate_name($self,$parents);
        $self->stash(PARENTS => $parents) if $parents;
    }
};

sub list{
    my $self = shift;
    return if !access($self);

    my $data = Utils::Accounts::get_all_parts();
    $self->stash( parts => $data );

    for my $part_id (keys %{$data}){
        my $sections = Utils::Accounts::get_sections($part_id);
        $data->{$part_id}{sections} = $sections;

        for my $section_id (keys %{$sections}){
            my $accounts = Utils::Accounts::get_accounts($section_id);
            $sections->{$section_id}{accounts} = $accounts;
            for my $account_id (keys %{$accounts}){
                my $account = $sections->{$section_id}{accounts}{$account_id};
                $account->{subcontos} = Utils::Accounts::get_subcontos($account_id);
            }
        }
    }
    Utils::Accounts::normalize_local(
        $data,
        Utils::Languages::get(),
        Utils::Languages::current($self));
};

sub generate_name{
    my ($self,$hashref) = @_;
    Utils::Accounts::normalize_local(
        $hashref,
        Utils::Languages::get(),
        Utils::Languages::current($self));
}

sub validate4add_part{
    my $self = shift;
    my $data =  validate($self,['rus','id'],['eng','uzb','type']);
    if ( $data->{id} !~ /^\d+$/ ){
        $data->{error} = 1 ; 
        $self->stash('id_class' => 'error');
        warn "Accounts:validate4add_part: id is not numeric!";
    } else {
        my $parent_id = "$data->{object_name} $data->{id}";
        my $db = Db->new();
        if( $db->get_objects({id => [$parent_id]}) ){
            $data->{error} = 1 ;
            warn "Accounts:validate4add_part: such object already exists!";
        }
    }
    return($data);
};

sub validate{
    my ($self,$mandatories,$optionals) = @_;
    my $data = { 
        object_name => $self->param('object_name'),
        updater => Utils::User::current($self) };
    for my $field (@{$mandatories}){
        $data->{$field} = Utils::trim $self->param($field);
        if ( !$data->{$field} ){
            $data->{error} = 1 ;
            $self->stash(($field . '_class') => 'error');
        }
    }
    for my $field (@{$optionals}){
        $data->{$field} = $self->param($field) if $self->param($field);
    }
    return($data);
};

sub fix_subconto{
    my $self = shift;
    return if !access($self);

    my $id = $self->param('payload');
    my $pnew = $self->param('pnew');
    my $db = Db->new();
    my $parent_new = $db->get_objects({id=>[$pnew]});
    my $pold = $self->param('pold');
    if( $pnew && $id && $pnew && $pold ) { 
        $db->del_link($id,$pold);
        $db->set_link('account',$pnew,'account subconto',$id);
    } else {
        warn "Accounts:fix_subconto:error parameters are not properly defined!";
    }
    $self->redirect_to("/accounts/list#$id"); 
};

sub fix_account{
    my $self = shift;
    return if !access($self);

    my $idold = $self->param('payload');
    my $idnew = $self->param('idnew');
    my $sid   = $self->param('sid');
    my $aid   = $self->param('aid');
    if( $idold && $idnew && $sid && $aid ) { 
        my $db = Db->new();
	    if ( $db->change_id($idold,$idnew) && $db->change_name('account',$idnew) ){
            $db->del_link($idold,$aid);
            $db->set_link('account',$idnew,'account section',$sid);
        }
    } else {
        warn "Accounts:fix_account:error parameters are not properly defined!";
    }
    $self->redirect_to("/accounts/list#$idnew"); 
};

sub delete_subconto{
    my $self = shift;
    return if !access($self); 
    
    my $id = $self->param('payload');
    my $parent = $self->param('parent');
    if ( !$id || !$parent ){
        warn "Accounts:delete_subconto:error parameters are not properly defined!";
        $self->redirect_to("/accounts/list/$id");
        return;
    }

    my $db = Db->new();
    $db->del_link($id,$parent);
    $db->del($id);
    $self->redirect_to("/accounts/list");
};

sub edit{
    my $self = shift;
    return if !access($self);

    my $id = $self->param('payload');
    if( !$id ) { 
        $self->redirect_to('/accounts/list'); 
        warn "Accounts:edit:error id not defined!";
        return; 
    }

    my $method = $self->req->method;
    my $db = Db->new();
    if ( $method =~ /POST/ ){
        my $data = validate( $self, ['rus'], ['eng','uzb','type'] );
        if( !exists($data->{error}) ){
            $data->{id} = $id;
            if( $db->update($data) ){
                $self->stash(success => 1);
            } else {
                $self->stash(error => 1);
                warn 'Accounts:edit:ERROR: could not update!';
            }
        } else {
            $self->stash(error => 1);
        }
    } 
    my $data = $db->get_objects({id=>[$id]});
    if ( !$data ){
        $self->redirect_to("/accounts/list#$id");
        warn "Accounts:edit:error id not found!";
        return;
    }
    my $parent_name = Utils::Accounts::get_parent_name($data->{$id}{object_name});
    my $child_name  = Utils::Accounts::get_child_name($data->{$id}{object_name});
    $db->attach_links($data,'PARENTS',$parent_name,['rus','eng','uzb']) if $parent_name;
    $db->attach_links($data,'CHILDS' ,$child_name,['rus','eng','uzb']) if $child_name;
    if( $data ){
        generate_name($self,$data);
        for my $key (keys %{$data->{$id}} ){
            $self->stash($key => $data->{$id}->{$key});
        }
        $self->stash( types => 
                Utils::Accounts::get_types4select($self,$data->{$id}{type})
            ) if $data->{$id}{object_name} eq Utils::Accounts::get_account_name();
    } else {
        redirect_to("/accounts/list#$id");
    }
};


# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
