package Buh1::Companies;
{
    use Mojo::Base 'Mojolicious::Controller';
    use Data::Dumper;
    use Utils::Filter;

    my $OBJECT_NAME         = 'company';
    my $OBJECT_NAMES        = 'companies';
    my $DELETED_OBJECT_NAME = 'deleted company';

    sub list {
        my $self = shift;
        _select_objects( $self, $OBJECT_NAME, '' );
    }

    sub deleted {
        my $self = shift;
        _select_objects( $self, $DELETED_OBJECT_NAME, '/companies/deleted' );
    }

    sub _select_objects {
        my ( $self, $name, $path ) = @_;

        my $filter  = Utils::Filter::get_filter($self);
        my $db      = Db->new($self);
        my $objects = $db->get_filtered_objects(
            {
                self          => $self,
                name          => $name,
                names         => $OBJECT_NAMES,
                exist_field   => 'name',
                filter_value  => $filter,
                filter_prefix => " field='name' ",
                result_fields => [ 'name', 'description' ]
            }
        );
        $self->stash( path      => $path );
        $self->stash( companies => $objects )
          if $objects && scalar( keys %{$objects} );

        $db->links_attach( $objects, 'users', 'user', ['email'] );
        
        for my $cid ( keys %{$objects} ) {
            if ( exists $objects->{$cid}{users} ) {
                my $users = $objects->{$cid}{users};
                for my $uid ( keys %{$users} ) {
                    $users->{$uid}{access} =
                      $db->get_linked_value( 'access', $cid, $uid );
                }
            }
        }

        return ($objects);
    }

    sub restore {
        my $self = shift;
        my $id   = $self->param('payload');
        if ($id) {
            my $db = Db->new($self);
            $db->change_name( $OBJECT_NAME, $id );
        }
        else {
            warn "Companies:restore:error company id not defined!";
        }
        $self->redirect_to('/companies/deleted');
    }

    sub validate {
        my $self = shift;
        my $data = {
            object_name => $OBJECT_NAME,
            creator     => Utils::User::current($self)
        };
        $data->{name} = Utils::trim $self->param('name');

        # $data->{access} = $self->param('access');
        if ( !$data->{name} ) {
            $data->{error} = 1;
            $self->stash( name_class => "error" );
        }
        $data->{description} = Utils::trim $self->param('description')
          if Utils::trim $self->param('description');
        return ($data);
    }

    sub del {
        my $self = shift;
        my $id   = $self->param('payload');
        if ($id) {
            my $db = Db->new($self);
            $db->change_name( $DELETED_OBJECT_NAME, $id );
        }
        else {
            warn "Companies:delete:error company id not defined!";
        }
        $self->redirect_to('/companies/list');
    }

    sub remove_user {
        my $self    = shift;
        my $id      = $self->param('payload');
        my $user_id = $self->param('user');
        my $db      = Db->new($self);
        $db->del_link( $id, $user_id );
        $db->del_linked_value( 'access', $id, $user_id );
        $self->redirect_to("/companies/edit/$id?success=1");
    }

    sub add_user {
        my $self    = shift;
        my $id      = $self->param('payload');
        my $user_id = $self->param('user');
        my $db      = Db->new($self);
        $db->set_link( $id, $user_id );
        $self->redirect_to("/companies/edit/$id");
        $self->redirect_to("/companies/edit/$id?success=1");
    }

    sub change_access {
        my $self        = shift;

        my $id          = $self->param('payload');
        my $user_id     = $self->param('user_id');
        my $user_access = $self->param('user_access');
        my $db          = Db->new($self);
        $db->del_linked_value( 'access', $id, $user_id );

        # delete all old linkes
        $db->set_linked_value( 'access', $id, $user_id, $user_access );
        $self->redirect_to("/companies/edit/$id?success=1");
    }

    sub edit {
        my $self = shift;
        return if !$self->who_is('global','user');

        $self->stash( edit_mode => 1 );
        my $id = $self->param('payload');
        if ( !$id ) {
            $self->redirect_to('/companies/list');
            warn "Companies:edit:error company ID not found!";
            return;
        }

        my $db = Db->new($self);

        # POST part
        if ( $self->req->method =~ /POST/ ) {
            my $data = validate($self);
            if ( !exists( $data->{error} ) ) {
                $data->{id} = $id;
                if ( $db->update($data) ) {
                    $self->stash( success => 1 );
                }
                else {
                    $self->stash( error => 1 );
                    warn 'Companies:edit:ERROR: could not update company!';
                }
            }
            else {
                $self->stash( error => 1 );
            }
        }
        ############

        my ( $non_company_users, $company_users ) =
          $db->get_difference( $id, 'user', 'email' );

        my $company_users_hash = {};
        for my $user ( @{$company_users} ) {
            my ( $user_id, $user_mail ) = ( $user->[1], $user->[0] );
            my $user_access = $db->get_linked_value( 'access', $id, $user_id );
            $company_users_hash->{$user_mail} = {
                id     => $user_id,
                access => $user_access,
            };
        }

        my $company_extra = {
            non_company_users  => Utils::sort_array_ref($non_company_users),
            company_users      => Utils::sort_array_ref($company_users),
            company_users_hash => $company_users_hash
        };

        if ( my $company = $db->get_objects( { id => [$id] } ) ) {
            $company->{$id}{EXTRA} = $company_extra;
            $self->stash( company => $company->{$id} );
        }
        else {
            redirect_to('/companies/list');
        }
        $self->render('/companies/add');
    }

    sub add {
        my $self = shift;

        if ( $self->req->method =~ /POST/ ) {

            # check values
            my $data = validate($self);

            if ( !exists( $data->{error} ) ) {
                my $db = Db->new($self);
                if ( my $id = $db->insert($data) ) {
                    $self->redirect_to("/companies/edit/$id");
                }
                else {
                    $self->stash( error => 1 );
                    warn 'Companies:add:ERROR: could not add new company!';
                }
            }
            else {
                $self->stash( error => 1 );
            }
        }
        $self->render();
    }

    1;

};
