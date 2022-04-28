package Buh1::Users;
{
    use Mojo::Base 'Mojolicious::Controller';
    use Db;
    use Auth;
    use Data::Dumper;
    use Utils::Filter;

    my $OBJECT_NAME         = 'user';
    my $OBJECT_NAMES        = 'users';
    my $DELETED_OBJECT_NAME = 'deleted user';

    sub _select_objects {
        my ( $self, $name, $path ) = @_;

        my $filter  = Utils::Filter::get_filter($self);
        my $db      = Db->new($self);
        my $objects = $db->get_filtered_objects(
            {
                self          => $self,
                name          => $name,
                names         => $OBJECT_NAMES,
                exist_field   => 'email',
                filter_value  => $filter,
                filter_prefix => " field='email' ",
                result_fields => [ 'email', 'description' ],
                path          => '/users/deleted'
            }
        );
        $self->stash( path  => $path );
        $self->stash( users => $objects )
          if $objects && scalar( keys %{$objects} );
        $db->links_attach( $objects, 'companies', 'company', ['name'] );
        for my $uid ( keys %{$objects} ) {
            if ( exists $objects->{$uid}{companies} ) {
                my $companies = $objects->{$uid}{companies};
                for my $cid ( keys %{$companies} ) {
                    $companies->{$cid}{access} =
                      $db->get_linked_value( 'access', $cid, $uid );
                }
            }
        }
        return ($objects);
    }

    sub list {
        my $self = shift;
        _select_objects( $self, $OBJECT_NAME, '' );
    }

    sub deleted {
        my $self = shift;
        _select_objects( $self, $DELETED_OBJECT_NAME, '/users/deleted' );
    }

    sub restore {
        my $self = shift;
        my $id   = $self->param('payload');
        if ($id) {
            my $db = Db->new($self);
            $db->change_name( $OBJECT_NAME, $id );
        }
        else {
            warn "Users:restore:error user id not defined!";
        }
        $self->redirect_to('/users/deleted');
    }

    sub validate_passwords {
        my $self = shift;
        my $data = shift;
        if (
            !Utils::validate_passwords(
                $data->{password1}, $data->{password2}
            )
          )
        {
            $data->{error} = 1;
            $self->stash( password1_class => "error" );
            $self->stash( password2_class => "error" );
        }
        else {
            $data->{password} = Auth::salted_password( $data->{password1} );
            delete $data->{password1};
            delete $data->{password2};
        }
    }

    sub validate_email {
        my ( $self, $email ) = @_;
        return (0) if ( !$email || !Utils::validate_email($email) );
        my $db = Db->new($self);
        return (0) if ( $db->get_user($email) );
        return (1);
    }

    sub validate {
        my ( $self, $edit_mode ) = @_;
        my $data = {
            object_name    => $OBJECT_NAME,
            creator        => Utils::User::current($self),
            extended_right => $self->param('extended_right')
        };
        if ( !$edit_mode ) {
            $data->{email} = Utils::trim $self->param('email');
            if ( !validate_email( $self, $data->{email} ) ) {
                $data->{error} = 1;
                $self->stash( email_class => "error" );
            }
        }
        $data->{description} = Utils::trim $self->param('description')
          if Utils::trim $self->param('description');
        $data->{password1} = Utils::trim $self->param('password1');
        $data->{password2} = Utils::trim $self->param('password2');
        if ( $edit_mode && !$data->{password1} && !$data->{password2} ) {
            delete $data->{password1};
            delete $data->{password2};
            return ($data);
        }
        validate_passwords( $self, $data );
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
            warn "Users:delete:error user id not defined!";
        }
        $self->redirect_to('/users/list');
    }

    sub remove_company {
        my $self    = shift;
        my $user_id = $self->param('payload');
        my $id      = $self->param('company');
        if ( my ($db) = Db->new($self) ) {
            $db->del_linked_value( 'access', $id, $user_id );
            $db->del_link( $id, $user_id );
        }
        $self->redirect_to("/users/edit/$user_id");
    }

    sub edit {
        my $self    = shift;
        my $user_id = $self->param('payload');
        if ( !$user_id ) {
            $self->redirect_to('/users/list');
            warn "Users:edit:error user id not defined!";
            return;
        }
        $self->stash( user_id => $user_id );
        my ( $db, $data ) = ( Db->new($self), undef );
        if ( $self->req->method eq 'POST' ) {
            $data = validate( $self, 1 );
            if ( !exists( $data->{error} ) ) {
                $data->{id} = $user_id;
                if ( $db->update($data) ) {
                    $self->stash( success => 1 );
                }
                else {
                    $self->stash( error => 1 );
                    warn 'Users:edit:ERROR: could not update user!';
                }
            }
            else {
                $self->stash( error => 1 );
            }
        }
        $data = $db->get_objects(
            {
                id    => [$user_id],
                field => [ 'email', 'description', 'extended_right' ]
            }
        );
        if ($data) {
            $db->links_attach( $data, 'companies', 'company', ['name'] );
            for my $key ( keys %{ $data->{$user_id} } ) {
                $self->stash( $key => $data->{$user_id}->{$key} );
            }
            $self->stash( user => $data->{$user_id} );
        }
        else {
            redirect_to('/users/list');
        }
        $self->render();
    }

    sub add {
        my $self = shift;
        $self->stash( user_id => undef );
        my $method = $self->req->method;
        if ( $method =~ /POST/ ) {

            # check values
            my $data = validate( $self, 0 );

            # add
            if ( !exists( $data->{error} ) ) {
                my $db = Db->new($self);
                if ( $db->insert($data) ) {
                    $self->redirect_to('/users/list');
                }
                else {
                    $self->stash( error => 1 );
                    warn 'Users:add:error: could not add new user!';
                }
            }
            else {
                $self->stash( error => 1 );
            }
        }
        $self->render('/users/edit');
    }

    1;

};
