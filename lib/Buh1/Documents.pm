package Buh1::Documents;
{

=encoding utf8

=head1 NAME

    Documents

=cut

    use strict;
    use warnings;
    use utf8;
    use Mojo::Base 'Mojolicious::Controller';
    use Data::Dumper;
    use Utils::Db;
    use Utils::Digital;
    use Utils::Documents;
    use Encode;
    use DbClient;

    my $OBJECT_NAME   = 'document';
    my $OBJECT_NAMES  = 'documents';
    my @OBJECT_FIELDS = (
        'object_name',              'account',
        'bt',                       'debet',
        'credit',                   'type',
        'document number',          'date',
        'permitter',                'permitter debet',
        'permitter inn',            'permitter bank name',
        'permitter bank code',      'currency amount',
        'beneficiary',              'beneficiary credit',
        'beneficiary bank name',    'beneficiary bank code',
        'currency amount in words', 'details',
        'executive',                'accounting manager'
    );
    my @OBJECT_HEADER_FIELDS = ( 'docid', 'account', 'bt', 'debet', 'credit' );

    sub set_test_data {
        my $self          = shift;
        my $_sum          = int( rand(10000000) );
        my $_sum_in_words = Utils::Digital::sum2ru_words($_sum);
        $self->req->params->merge(
            'document number' =>
              Utils::Documents::get_document_number_next($self),
            'permitter debet'          => '01234567890123456789',
            'permitter'                => 'ООО "УЗБЕКЛОЙИХАСОЗЛАШ"',
            'permitter debet'          => '01234567890123456789',
            'permitter inn'            => '123456789',
            'permitter bank name'      => 'ЧОАКБ ИнФинБанк',
            'permitter bank code'      => '01041',
            'currency amount'          => $_sum,
            'currency amount in words' => $_sum_in_words,
            'beneficiary'              => 'ОАО "Узбекистон Темирйуллари"',
            'beneficiary credit'       => '99999999999999999999',
            'beneficiary bank name'    => 'АИКБ "Ипак Йули"',
            'beneficiary bank code'    => '14230',
            'details'                  => 'Оплата за установку кронштейна!',
            'executive'                => 'Петров И.У.',
            'accounting manager'       => 'Камолова К.С.'
        );
    }

    sub set_form_header {
        my $self       = shift;
        my $parameters = {};
        for my $header ( ( 'account', 'bt', 'debet', 'credit' ) ) {
            my $value = $self->param($header) || $self->stash($header);
            if ($value) {
                $parameters->{$header} = $value;
            }
            else {
                warn "Could not find proper value for '$header'";
                $self->stash(
                    error         => 1,
                    error_message =>
                      $self->ml('Could not set headers for document!')
                );
                return;
            }
        }
        my $db       = Db->new($self);
        my $dheaders = {};               # Document headers
        for my $key ( keys %{$parameters} ) {
            my $id = $parameters->{$key};
            if ( !$id ) {
                warn "No ID to linked object($key) defined!";
                $self->stash( error => 1 );
                return;
            }
            my $db_object = $db->get_objects( { id => [$id] } );
            if ( !$db_object ) {
                warn "No db object($id) found in database!";
                $self->stash( error => 1 );
                return;
            }
            Utils::Languages::generate_name( $self, $db_object );
            $dheaders->{$key} = $db_object->{$id};
        }
        $self->stash( dheaders => $dheaders );
        return (1);
    }

    sub list {
        my $self = shift;
        return if !$self->who_is( 'local', 'reader' );

        my $db_client = Utils::Db::client($self);
        if ($db_client) {
            _select_objects( $self, $db_client, $OBJECT_NAME, '' );
        }
        else {
            $self->reditect_to('desktop/select_company');
        }
    }

    sub _select_objects {
        my ( $self, $db, $name, $path ) = @_;

        my $filter  = Utils::Filter::get_filter($self);
        my $objects = $db->get_filtered_objects(
            {
                self          => $self,
                name          => $name,
                names         => $OBJECT_NAMES,
                exist_field   => 'document number',
                filter_value  => $filter,
                filter_prefix =>
                  " field NOT IN('bt','debet','credit','account') ",
                result_fields => [
                    'document number', 'currency amount',
                    'details',         'date',
                    'account',         'type'
                ],
                path => ''
            },
            1
        );
        $self->stash( path      => $path );
        $self->stash( documents => $objects )
          if $objects && scalar( keys %{$objects} );
    }

    sub validate_document {
        my $self   = shift;
        my $errors = {};
        my $data   = {
            document => {
                object_name => $OBJECT_NAME,
                creator     => Utils::User::current($self),
            }
        };
        my @fields = @OBJECT_FIELDS;
        for my $field (@fields) {
            my $value = Utils::trim $self->param($field);
            if ($value) {
                $data->{document}{$field} = $value;
            }
            else {
                $errors->{$field} = 'error';
            }
        }

        # recalculate amount if needs
        my $currency_amount = $self->param('currency amount');

        # check currency amount in words
        if ( $self->param('currency amount') ne
            $self->param('old currency amount') )
        {
            $self->req->params->merge( 'currency amount in words' =>
                  Utils::Digital::sum2ru_words($currency_amount) );
            $self->req->params->merge(
                'old currency amount' => $currency_amount );
            $errors->{'currency amount'} = 'error';
        }

        # check for document number existance
        if (
            Utils::Documents::document_number_exist(
                $self, $data->{document}{'document number'},
                $self->param("docid")
            )
          )
        {
            $errors->{'document number'} = 'error';
        }

        # validate document date
        my $date = Utils::validate_date( $data->{document}{date} );
        if ($date) {
            $data->{document}{date} = $date;
        }
        else {
            $errors->{'date'} = 'error';
        }

        # final
        $data->{errors_count} = scalar( keys( %{$errors} ) );
        $data->{errors}       = $errors;

        return ($data);
    }

    sub validate_document_header {
        my $self   = shift;
        my $result = {};
        for my $header (@OBJECT_HEADER_FIELDS) {
            my $value = $self->param($header);
            if ( !$value ) {
                warn "No value found for mandatory $header field";
                return;
            }
            $result->{$header} = $value;
        }
        $result->{object_name} = $OBJECT_NAME;
        $result->{id}          = $result->{docid};
        delete $result->{docid};
        return ($result);
    }

    sub update_document_header {
        my $self = shift;

        if ( my $data = validate_document_header($self) ) {
            my $db_client = Utils::Db::client($self);
            if ( $db_client->update($data) ) {
                $self->stash( success => 1 );
            }
            else {
                $self->stash( error => 1 );
                warn 'Could not update objects!';
            }
        }
        my $account = $self->param("account");
        my $docid   = Utils::Documents::detach($self);
        $self->redirect_to("/documents/update/$account?docid=$docid");
    }

    sub cancel_update_document_header {
        my $self = shift;

        my $account = $self->param("account");
        my $docid   = Utils::Documents::detach($self);
        $self->redirect_to("/documents/update/$account?docid=$docid");
    }

    sub print {
        my $self = shift;
        return if !$self->who_is( 'local', 'reader' );

        my $docid = $self->param('account');
        if ($docid) {
            deploy_document( $self, $docid );
        }
    }

    # sub add {
    #     my $self = shift;
    #     return if !$self->who_is( 'local', 'reader' );

    #     if ( $self->req->method eq 'POST' ) {
    #         my $data = validate_new_doc($self);
    #         if ( !$data->{errors_count} ) {
    #             my $db_client = Utils::Db::client($self);

    #             if ( my $id = $db_client->insert( $data->{document} ) ) {
    #                 $self->redirect_to(
    #                     "/documents/update/$id?docid=$id&success=1");
    #             }
    #             else {
    #                 $self->stash( error => 1 );
    #                 warn 'Could not insert [document] object!';
    #             }
    #         }
    #         else {
    #             $self->stash( errors => $data->{errors} );
    #         }
    #     }
    #     else {
    #         $self->stash( document => set_test_data($self) );
    #     }
    # }

    sub update {
        my $self = shift;
        return if !$self->who_is( 'local', 'reader' );

        my $id      = $self->param('docid');
        my $account = $self->param('account');
        my $bt      = $self->param('bt');

        my $isPost = ( $self->req->method =~ /POST/ )
          && ( ( !$self->param('post') )
            || ( $self->param('post') !~ /^preliminary$/i ) );

        if ($isPost) {
            return if !$self->who_is( 'local', 'writer' );
            my $data = validate_document( $self, $id );
            if ( !$data->{errors_count} ) {
                my $db_client = Utils::Db::client($self);
                if ( defined $id ) {
                    $data->{document}{id} = $id;
                    if ( $db_client->update( $data->{document} ) ) {
                        $self->stash( success => 1 );
                        $self->redirect_to(
                            "/documents/update/$account?docid=$id&success=1");
                    }
                    else {
                        $self->stash( error => 1 );
                        warn 'Could not update objects!';
                    }
                }
                else {
                    if ( $id = $db_client->insert( $data->{document} ) ) {
                        $self->redirect_to(
                            "/documents/update/$account?docid=$id&success=1");
                    }
                    else {
                        $self->stash( error => 1 );
                        warn 'Could not insert document object!';
                    }
                }
            }
            else {
                $self->stash( error  => 1 );
                $self->stash( errors => $data->{errors} );
                if ( $self->param('fill_with_test_data') ) {
                    set_test_data($self);
                    $self->req->params->merge( 'fill_with_test_data' => undef );
                }
            }
        }
        else {
            if ($id) {    # TODO: Here refactor needs
                deploy_document( $self, $id );
            }
            else {
                my $template = $self->param('template');
                if ($template) {
                    deploy_document( $self, $template );
                }
            }
        }
        set_form_header($self);    # set headers for document
    }

    sub deploy_document {
        my ( $self, $id ) = @_;
        return if !$self->who_is( 'local', 'reader' );
        return if !$self || !$id;

        my $db_client = Utils::Db::client($self);
        if ($db_client) {
            my $objects = $db_client->get_objects( { id => [$id] } );
            if ( $objects && exists( $objects->{$id} ) ) {
                my $document = $objects->{$id};

                # $self->stash( document => $document );
                for my $key ( keys %{$document} ) {
                    $self->req->params->merge( $key => $document->{$key} );
                }
            }
        }
    }

    1;

};

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>


