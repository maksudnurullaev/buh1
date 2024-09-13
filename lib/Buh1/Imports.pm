package Buh1::Imports;

use Data::Dumper;
use utf8;
use open qw( :std :encoding(UTF-8) );

=encoding utf8

=head1 NAME

    Accounts controller

=cut

use Mojo::Base 'Mojolicious::Controller';
use Utils::Accounts;
use Data::Dumper;
use Utils::Cacher;

my $debug_mode = 0;

my $apart_name        = Utils::Accounts::get_account_part_name();
my $asection_name     = Utils::Accounts::get_account_section_name();
my $account_name      = Utils::Accounts::get_account_name();
my $asubconto_name    = Utils::Accounts::get_account_subconto_name();
my $part_id_prefix    = $apart_name . ' ';
my $section_id_prefix = $asection_name . ' ';

sub get_web_resource {
    my $url = shift;
    return (undef) if !defined($url);

    my $ua  = Mojo::UserAgent->new;
    my $res = $ua->get($url)->result;
    return ($res) if $res->is_success;

    if    ( $res->is_error )    { warn '$res->message'; }
    elsif ( $res->code == 301 ) { warn $res->headers->location; }
    else                        { warn 'Unknown error!'; }

    return (undef);
}

sub get_dom_deep_text {
    my $dom = shift;
    return if !$dom;

    my $collections =
      $dom->descendant_nodes->grep( sub { $_->type eq 'text' } );
    return $collections->size ? $collections->first->to_string : '';
}

sub parse_accounts {
    my ( $self, $dom, $result ) = ( shift, shift, {} );
    if ( !$self || !$dom ) { warn "Empty parameters!"; return; }

    my ( $current_part, $current_section, $current_account );
    my ( $current_part_num, $current_section_num ) = ( 1, 1 );

    for my $div ( $dom->find('div[class="TABLE_STD"]')->each ) {
        my $TRs = $div->find('tr[tabindex="1"]');
        for my $TR ( $TRs->each ) {
            my $TDs = $TR->find('td');

            if ( $TDs->size == 1
                && ( my $text = get_dom_deep_text( $TDs->[0] ) ) )
            {
                if ( $text =~ /^ЧАСТЬ/ ) {    # . PARTs
                    warn ". $text" if $debug_mode;
                    $current_part = $part_id_prefix . ( $current_part_num++ );
                    $result->{$current_part} = {
                        rus => $text    #,
                                        #sections => {}
                    };
                }
                elsif ( $text =~ /^РАЗДЕЛ/ ) {    # .. SECTIONs
                    warn ".. $text" if $debug_mode;
                    $current_section =
                      $section_id_prefix . ( $current_section_num++ );
                    $result->{$current_part}{sections}{$current_section} = {
                        rus => $text    #,
                                        #accounts => {}
                    };
                }
            }
            elsif ( $TDs->size == 3
                && ( $text = get_dom_deep_text( $TDs->[0] ) ) )
            {
                if ( $text =~ /^\d{2}00/ ) {    # ... ACCOUNTs
                    my ( $name, $type ) = (
                        get_dom_deep_text( $TDs->[1] ),
                        get_dom_deep_text( $TDs->[2] )
                    );
                    next                          if !$name;
                    warn "... $text $name $type " if $debug_mode;
                    my ( $acc_num, $acc_name, $acc_type ) =
                      ( $text, $name, $type );
                    $current_account = $acc_num;
                    $result->{$current_part}{sections}{$current_section}
                      {accounts}{$current_account} = {
                        type => Utils::Accounts::get_type($acc_type),
                        rus  => "$acc_num $acc_name"                    #,
                              #subconto => {}
                      };
                }
                elsif ( $text =~ /^\d{4}/ ) {    # .... SUBCONTOs
                    my $name = get_dom_deep_text( $TDs->[1] );
                    next                     if !$name;
                    warn ".... $text $name " if $debug_mode;
                    $result->{$current_part}{sections}{$current_section}
                      {accounts}{$current_account}{subconto}{$text} =
                      { rus => "$text $name" };
                }
                elsif ( $text =~ /^\d{3}/ ) {    # off-balance
                    my $name = get_dom_deep_text( $TDs->[1] );
                    next                   if !$name;
                    warn ".. $text $name " if $debug_mode;
                    $current_section =
                      $section_id_prefix . ( $current_section_num++ );
                    $result->{$current_part}{sections}{$current_section} = {
                        rus => "$text $name"    #,
                                                #accounts => {}
                    };
                }
            }
        }
    }
    return $result;
}

sub lex {
    my $self = shift;
    return if !$self->who_is( 'global', 'admin' );
    if ( $self->req->method =~ /POST/ ) {    #POST
        my ( $url, $definitions, $req_params ) = (
            $self->param('url'),
            $self->param('definitions'),
            $self->req->params->to_hash
        );
        my $validation = $self->validation;
        $validation->input( { url => $url, definitions => $definitions } );

        if ( $validation->required('url')->http_url()->is_valid ) {

            #check cache || result
            my $html_dom_all =
              $req_params->{use_cache} ? is_cached( $self, $url ) : undef;
            if ( !defined($html_dom_all) ) {
                my $res = get_web_resource($url);
                cache_it( $self, $url, $html_dom_all )
                  if defined($res)
                  && ( $html_dom_all = $res->dom );
                warn "Cache dom!" if $debug_mode;
            }
            else {
                warn "Use cached version of dom!" if $debug_mode;
            }
            return if !defined($html_dom_all);

            # parse
            if ( $req_params->{parse_variant} eq 'accounts' ) {
                my $result = parse_accounts( $self, $html_dom_all );
                $self->stash( parts => $result );
            }
            elsif ( $req_params->{parse_variant} eq 'operations' ) {
                warn uc( $req_params->{parse_variant} )
                  . " parsing not defined yet!";
            }
            else { warn "Not defined parse variant!"; }
        }
        else {
            warn "URL: !!!NOT VALID!!!" if $debug_mode;
        }

    }

}

sub add_part {
    my $self = shift;
    return if !Utils::Accounts::authorized2modify($self);

    my ( $data, $id );

    # 1. Test for payload - parents account!
    my $parent_id = $self->param('payload');
    my ( $parents, $object_name4form );
    my $db = Db->new($self);
    if ($parent_id) {
        $parents = $db->get_objects( { id => [$parent_id] } );
        if ( !$parents ) {
            warn "Accounts:add_part: no parents! Redirecting..." if $debug_mode;
            $self->redirect_to('/accounts/list');
            return;
        }
        $object_name4form =
             Utils::Accounts::get_child_name_by_id( $self, $parent_id )
          || Utils::Accounts::get_account_part_name();
    }
    else {
        $object_name4form = Utils::Accounts::get_account_part_name();
    }
    $self->stash( object_name => $object_name4form );

    # 2. Process post if needs
    my $method = $self->req->method;
    if ( $method =~ /POST/ ) {
        $data = Utils::Accounts::validate4add_part($self);
        if ( !exists( $data->{error} ) ) {
            my $object_name = $data->{object_name};

            # set new id
            $data->{id} = "$object_name $data->{id}";
            if ( $id = $db->insert($data) ) {
                $db->set_link( $parent_id, $id ) if $parents;
                $self->redirect_to("/accounts/edit/$id");
                clear_cache($self);
                return;
            }
            else {
                $self->stash( error => 1 );
                warn 'Accounts:edit:ERROR: could not update!' if $debug_mode;
            }
        }
        else {
            $self->stash( error => 1 );
        }
    }
    $data = $db->get_objects( { id => [$id] } );
    $self->stash( types => Utils::Accounts::get_types4select($self) )
      if $object_name4form eq Utils::Accounts::get_account_name();
    if ($data) {
        $data->{PARENTS} = $parents->{$parent_id} if $parents;
        Utils::Languages::generate_name( $self, $data );
        for my $key ( keys %{ $data->{$id} } ) {
            $self->stash( $key => $data->{$id}->{$key} );
        }
    }
    else {
        Utils::Languages::generate_name( $self, $parents );
        $self->stash( PARENTS => $parents ) if $parents;
    }
}

sub list {
    my $self = shift;
    my $data;
    return ( $self->stash( parts => $data ) )
      if $data = is_cached( $self, 'data' );

    $data = Utils::Accounts::get_all_parts($self);
    for my $part_id ( keys %{$data} ) {
        my $sections = Utils::Accounts::get_sections( $self, $part_id );
        $data->{$part_id}{sections} = $sections;

        for my $section_id ( keys %{$sections} ) {
            my $accounts = Utils::Accounts::get_accounts( $self, $section_id );
            $sections->{$section_id}{accounts} = $accounts;
            for my $account_id ( keys %{$accounts} ) {
                my $account =
                  $sections->{$section_id}{accounts}{$account_id};
                $account->{subcontos} =
                  Utils::Accounts::get_subcontos( $self, $account_id );
            }
        }
    }
    Utils::Languages::generate_name( $self, $data );
    cache_it( $self, 'data', $data );
    $self->stash( parts => $data );
}

sub fix_subconto {
    my $self = shift;
    return if !Utils::Accounts::authorized2modify($self);

    my $id         = $self->param('payload');
    my $pnew       = $self->param('pnew');
    my $db         = Db->new($self);
    my $parent_new = $db->get_objects( { id => [$pnew] } );
    my $pold       = $self->param('pold');
    if ( $pnew && $id && $pnew && $pold ) {
        $db->del_link( $id, $pold );
        $db->set_link( $pnew, $id );
        clear_cache($self);
    }
    else {
        warn "Accounts:fix_subconto:error parameters are not properly defined!"
          if $debug_mode;
    }
    $self->redirect_to("/accounts/list#$id");
}

sub fix_account {
    my $self = shift;
    return if !Utils::Accounts::authorized2modify($self);

    my $idold = $self->param('payload');
    my $idnew = $self->param('idnew');
    my $sid   = $self->param('sid');
    my $aid   = $self->param('aid');
    if ( $idold && $idnew && $sid && $aid ) {
        my $db = Db->new($self);
        if (   $db->change_id( $idold, $idnew )
            && $db->change_name( 'account', $idnew ) )
        {
            $db->del_link( $idold, $aid );
            $db->set_link( $idnew, $sid );
            clear_cache($self);
        }
    }
    else {
        warn "Accounts:fix_account:error parameters are not properly defined!"
          if $debug_mode;
    }
    $self->redirect_to("/accounts/list#$idnew");
}

sub delete_subconto {
    my $self = shift;
    return if !Utils::Accounts::authorized2modify($self);

    my $id     = $self->param('payload');
    my $parent = $self->param('parent');
    if ( !$id || !$parent ) {
        warn
          "Accounts:delete_subconto:error parameters are not properly defined!";
        $self->redirect_to("/accounts/list/$id");
        return;
    }

    my $db = Db->new($self);
    $db->del_link( $id, $parent );
    $db->del($id);
    clear_cache($self);
    $self->redirect_to("/accounts/list");
}

sub edit {
    my $self = shift;

    my $id = $self->param('payload');
    if ( !$id ) {
        $self->redirect_to('/accounts/list');
        warn "Accounts:edit:error id not defined!" if $debug_mode;
        return;
    }

    my $method = $self->req->method;
    my $db     = Db->new($self);
    if ( $method =~ /POST/ ) {
        return if !Utils::Accounts::authorized2modify($self);

        my $data =
          Utils::Accounts::validate( $self, ['rus'], [ 'eng', 'uzb', 'type' ] );
        if ( !exists( $data->{error} ) ) {
            $data->{id} = $id;
            if ( $db->update($data) ) {
                $self->stash( success => 1 );
                clear_cache($self);
            }
            else {
                $self->stash( error => 1 );
                warn 'Accounts:edit:ERROR: could not update!' if $debug_mode;
            }
        }
        else {
            $self->stash( error => 1 );
        }
    }
    my $data = $db->get_objects( { id => [$id] } );
    if ( !$data ) {
        $self->redirect_to("/accounts/list#$id");
        warn "Accounts:edit:error id not found!" if $debug_mode;
        return;
    }
    my $parent_name =
      Utils::Accounts::get_parent_name( $data->{$id}{object_name} );
    my $child_name =
      Utils::Accounts::get_child_name( $data->{$id}{object_name} );
    my $langs = Utils::Languages::get();

    $db->links_attach( $data, 'PARENTS', $parent_name, $langs )
      if $parent_name;
    if ($child_name) {
        $db->links_attach( $data, 'CHILDS', $child_name, $langs )
          if $child_name;
    }
    elsif ($parent_name) {
        my $parent_id = ( keys %{ $data->{$id}{'PARENTS'} } )[0];
        my $friends   = { $parent_id => {} };
        $db->links_attach( $friends, 'FRIENDS',
            $data->{$id}{'object_name'}, $langs );
        $data->{$id}{'FRIENDS'} = $friends->{$parent_id}{'FRIENDS'};
    }

    $self->stash( has_child => $child_name )
      ;    # needs to 'add child' link in form

    if ( $data->{$id}{object_name} eq 'account' ) {    # attach bts
        $db->links_attach(
            $data, 'bts',
            'business transaction',
            Utils::merge2arr_ref(
                Utils::Languages::get(), 'number', 'debet', 'credit'
            )
        );
    }
    if ($data) {
        Utils::Languages::generate_name( $self, $data );
        for my $key ( keys %{ $data->{$id} } ) {
            $self->stash( $key => $data->{$id}->{$key} );
        }
        $self->stash( types =>
              Utils::Accounts::get_types4select( $self, $data->{$id}{type} ) )
          if $data->{$id}{object_name} eq Utils::Accounts::get_account_name();
    }
    else {
        redirect_to("/accounts/list#$id");
    }
}

# END OF PACKAGE

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
