package Buh1::Database;
{

    use Mojo::Base 'Mojolicious::Controller';
    use Data::Dumper;
    use Db;

    sub adb {    # (ADB) - Anonal double records
        my $self = shift;
        return if !$self->who_is('global', 'admin');

        _do_sql($self) if $self->req->method eq 'POST';
        $self->render();
    }

    sub counts {    # Count of DB objects
        my $self = shift;
        return if !$self->who_is('global', 'admin');

        _do_sql($self) if $self->req->method eq 'POST';
        $self->render();
    }

    sub _do_sql {
        my $self = shift;
        my $sql  = $self->param('sql');
        my $dbh  = Db->new($self);
        my $sth  = $dbh->get_from_sql($sql);
        $self->stash( table_rows         => $sth->fetchall_arrayref );
        $self->stash( table_column_names => $sth->{NAME_uc} );
    }

    sub view {
        my $self      = shift;
        return if !$self->who_is('global', 'admin');

        my $object_id = $self->param('payload');
        my $dbh       = Db->new($self);

        if ( $self->req->method eq 'POST' ) {
            my $action     = $self->req->params->every_param('action')->[0];
            my $forDeletes = $self->req->params->every_param('delete');

            if ( @{$forDeletes} && $action ) {
                if ( $action eq 'DELETE' ) {
                    my $dbc = $dbh->get_db_connection();
                    my $statement =
"update objects set id = ('DELETED ' || id) where rowid in ("
                      . join( ',', @{$forDeletes} )
                      . ") and id NOT LIKE 'DELETED%' ;";

                    $dbc->do($statement) or warn $dbc->errstr;
                }
                elsif ( $action eq 'RESTORE' ) {
                    my $dbc = $dbh->get_db_connection();
                    my $statement =
                        "update objects set id = substr(id,9) where rowid in ("
                      . join( ',', @{$forDeletes} )
                      . ") and id LIKE 'DELETED%' ;";

                    $dbc->do($statement) or warn $dbc->errstr;
                }
            }
            warn "No action defined!" if !$action;
            warn "No rows defined!"   if !@{$forDeletes};
        }

        my $sth = $dbh->get_from_sql(
            " SELECT ROWID, * FROM objects WHERE id = '$object_id' ; ");

        $self->stash( table_rows         => $sth->fetchall_arrayref );
        $self->stash( table_column_names => $sth->{NAME_uc} );

        $self->render();
    }

    1;

};
