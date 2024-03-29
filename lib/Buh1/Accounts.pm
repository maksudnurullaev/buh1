package Buh1::Accounts; {

=encoding utf8

=head1 NAME

    Accounts controller

=cut

use Mojo::Base 'Mojolicious::Controller';
use Utils::Accounts;
use Data::Dumper;
use Utils::Cacher;

sub add_part{
    my $self = shift;
    return if !Utils::Accounts::authorized2modify( $self ) ;

    my ($data,$id);
    # 1. Test for payload - parents account!
    my $parent_id = $self->param('payload');
    my ($parents, $object_name4form);
    my $db = Db->new($self);
    if ( $parent_id ){
        $parents = $db->get_objects({id=>[$parent_id]});
        if( !$parents ){
            warn "Accounts:add_part: no parents! Redirecting...";
            $self->redirect_to('/accounts/list');
            return;
        }
        $object_name4form = Utils::Accounts::get_child_name_by_id($self, $parent_id)
            || Utils::Accounts::get_account_part_name();
    } else {
        $object_name4form = Utils::Accounts::get_account_part_name();
    }
    $self->stash( object_name => $object_name4form );
    # 2. Process post if needs
    my $method = $self->req->method;
    if ( $method =~ /POST/ ){
        $data = Utils::Accounts::validate4add_part($self);
        if( !exists($data->{error}) ){
            my $object_name = $data->{object_name};
            # set new id
            $data->{id} = "$object_name $data->{id}";
            if( $id = $db->insert($data) ){
                $db->set_link($parent_id,$id) if $parents ;
                $self->redirect_to("/accounts/edit/$id");
                clear_cache($self);
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
        Utils::Languages::generate_name($self,$data);
        for my $key (keys %{$data->{$id}} ){
            $self->stash($key => $data->{$id}->{$key});
        }
    } else {
        Utils::Languages::generate_name($self,$parents);
        $self->stash(PARENTS => $parents) if $parents;
    }
};

sub list{
    my $self = shift;
    my $data;
    return( $self->stash( parts => $data) ) if $data = is_cached($self,'data');

    $data = Utils::Accounts::get_all_parts($self);
    for my $part_id (keys %{$data}){
        my $sections = Utils::Accounts::get_sections($self,$part_id);
        $data->{$part_id}{sections} = $sections;

        for my $section_id (keys %{$sections}){
            my $accounts = Utils::Accounts::get_accounts($self, $section_id);
            $sections->{$section_id}{accounts} = $accounts;
            for my $account_id (keys %{$accounts}){
                my $account = $sections->{$section_id}{accounts}{$account_id};
                $account->{subcontos} = Utils::Accounts::get_subcontos($self,$account_id);
            }
        }
    }
    Utils::Languages::generate_name($self, $data);
    cache_it($self,'data',$data);
    $self->stash( parts => $data );
};

sub fix_subconto{
    my $self = shift;
    return if !Utils::Accounts::authorized2modify( $self ) ;

    my $id = $self->param('payload');
    my $pnew = $self->param('pnew');
    my $db = Db->new($self);
    my $parent_new = $db->get_objects({id=>[$pnew]});
    my $pold = $self->param('pold');
    if( $pnew && $id && $pnew && $pold ) { 
        $db->del_link($id,$pold);
        $db->set_link($pnew,$id);
        clear_cache($self);
    } else {
        warn "Accounts:fix_subconto:error parameters are not properly defined!";
    }
    $self->redirect_to("/accounts/list#$id"); 
};

sub fix_account{
    my $self = shift;
    return if !Utils::Accounts::authorized2modify( $self ) ;

    my $idold = $self->param('payload');
    my $idnew = $self->param('idnew');
    my $sid   = $self->param('sid');
    my $aid   = $self->param('aid');
    if( $idold && $idnew && $sid && $aid ) { 
        my $db = Db->new($self);
        if ( $db->change_id($idold,$idnew) && $db->change_name('account',$idnew) ){
            $db->del_link($idold,$aid);
            $db->set_link($idnew,$sid);
            clear_cache($self);
        }
    } else {
        warn "Accounts:fix_account:error parameters are not properly defined!";
    }
    $self->redirect_to("/accounts/list#$idnew"); 
};

sub delete_subconto{
    my $self = shift;
    return if !Utils::Accounts::authorized2modify( $self ) ;
    
    my $id = $self->param('payload');
    my $parent = $self->param('parent');
    if ( !$id || !$parent ){
        warn "Accounts:delete_subconto:error parameters are not properly defined!";
        $self->redirect_to("/accounts/list/$id");
        return;
    }

    my $db = Db->new($self);
    $db->del_link($id,$parent);
    $db->del($id);
    clear_cache($self);
    $self->redirect_to("/accounts/list");
};

sub edit{
    my $self = shift;

    my $id = $self->param('payload');
    if( !$id ) { 
        $self->redirect_to('/accounts/list'); 
        warn "Accounts:edit:error id not defined!";
        return; 
    }

    my $method = $self->req->method;
    my $db = Db->new($self);
    if ( $method =~ /POST/ ){
        return if !Utils::Accounts::authorized2modify( $self ) ;

        my $data = Utils::Accounts::validate( $self, ['rus'], ['eng','uzb','type'] );
        if( !exists($data->{error}) ){
            $data->{id} = $id;
            if( $db->update($data) ){
                $self->stash(success => 1);
                clear_cache($self);
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
    my $langs        = Utils::Languages::get();

    $db->links_attach($data,'PARENTS',$parent_name,$langs) if $parent_name;
    if( $child_name ){
        $db->links_attach($data,'CHILDS' ,$child_name,$langs) if $child_name;
    } elsif ( $parent_name ) {
        my $parent_id = (keys %{$data->{$id}{'PARENTS'}})[0];
        my $friends = { $parent_id => {} };
        $db->links_attach($friends,'FRIENDS',$data->{$id}{'object_name'},$langs);
        $data->{$id}{'FRIENDS'} = $friends->{$parent_id}{'FRIENDS'} ;
    }

    $self->stash( has_child => $child_name ); # needs to 'add child' link in form

    if( $data->{$id}{object_name} eq 'account' ){ # attach bts
        $db->links_attach($data,
            'bts',
            'business transaction',
            Utils::merge2arr_ref(Utils::Languages::get(),'number','debet','credit'));
    }
    if( $data ){
        Utils::Languages::generate_name($self,$data);
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
