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

    sub set_new_data {
        return {
            'document number' =>
              Utils::Documents::get_document_number_next(shift),
            'permitter debet'       => '01234567890123456789',
            'permitter'             => 'ООО "УЗБЕКЛОЙИХАСОЗЛАШ"',
            'permitter debet'       => '01234567890123456789',
            'permitter inn'         => '123456789',
            'permitter bank name'   => 'ЧОАКБ ИнФинБанк',
            'permitter bank code'   => '01041',
            'currency amount'       => int( rand(10000000) ),
            'beneficiary'           => 'ОАО "Узбекистон Темирйуллари"',
            'beneficiary credit'    => '99999999999999999999',
            'beneficiary bank name' => 'АИКБ "Ипак Йули"',
            'beneficiary bank code' => '14230',
            'details'               => 'Оплата за установку кронштейна!',
            'executive'             => 'Петров И.У.',
            'accounting manager'    => 'Камолова К.С.'
        };
    }

    sub set_form_header {
        my $self       = shift;
        my $parameters = {};
        my @headers    = ( 'account', 'bt', 'debet', 'credit' );
        for my $header (@headers) {
            my $value = $self->param($header) || $self->stash($header);
            if ($value) {
                $parameters->{$header} = $value;
            }
            else {
                warn "Could not find proper value for '$header'";
                $self->stash( error => 1 );
                return;
            }
        }
        my $db = Db->new($self);
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
            $self->stash( $key => $db_object->{$id} );
        }
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
                exist_field   => 'bt',
                filter_value  => $filter,
                filter_prefix =>
                  " field NOT IN('bt','debet','credit','account') ",
                result_fields => [
                    'document number', 'currency amount',
                    'details',         'date',
                    'account',         'type'
                ],
                path => ''
            }
        );
        $self->stash( path      => $path );
        $self->stash( documents => $objects )
          if $objects && scalar( keys %{$objects} );
    }

    sub validate_new_doc {
        my $self   = shift;
        my $id     = shift;
        my $errors = {};
        my $data   = {
            object_name => $OBJECT_NAME,
            creator     => Utils::User::current($self),
        };
        my @fields = @OBJECT_FIELDS;
        for my $field (@fields) {
            next
              if grep { /$field/ }
              @OBJECT_HEADER_FIELDS;    # skip absent fields for new documents
            my $value = Utils::trim $self->param($field);
            if ($value) {
                $data->{$field} = $value;
            }
            else {
                $errors->{$field} = 'error';
                warn "Invalid field '$field'";
            }
        }

        # recalculate amount if needs
        my $currency_amount = $data->{'currency amount'};

        # check currency amount inwords
        $data->{'currency amount in words'} =
          Utils::Digital::sum2ru_words($currency_amount)
          if !$data->{'currency amount in words'};
        if ( $data->{'currency amount'} ne $self->param('old currency amount') )
        {
            $data->{'old currency amount'} = $data->{'currency amount'};
            $errors->{'currency amount'}   = 'error';
        }

        # check for document number existance
        if (
            Utils::Documents::document_number_exist(
                $self, $data->{'document number'}, $id
            )
          )
        {
            $errors->{'document number'} = 'error';
        }

        # validate document date
        my $date = Utils::validate_date( $data->{date} );
        if ($date) {
            $data->{date} = $date;
        }
        else {
            $errors->{'date'} = 'error';
        }

        # final
        $data->{errors_count} = scalar( keys( %{$errors} ) );
        $data->{errors}       = $errors;

        return ($data);
    }

    sub validate_old_doc {
        my $self = shift;
        my $id   = shift;
        my $data = {
            object_name => $OBJECT_NAME,
            creator     => Utils::User::current($self),
            errors      => [],
        };
        my @fields = @OBJECT_FIELDS;
        push( @fields, 'id' ) if $id;
        for my $field (@fields) {
            my $value = Utils::trim $self->param($field);
            if ($value) {
                $data->{$field} = $value;
            }
            else {
                $data->{error} = 1;
                push @{ $data->{errors} }, $field;
                $self->stash(
                    document => { ( $field . '_class' ) => 'error' } );
            }
        }

        # recalculate amount if needs
        my $currency_amount = $data->{'currency amount'};

        # my $currency_amount_in_words =
        #   Utils::Digital::sum2ru_words($currency_amount);
        if ($id) {
            my $old_currency_amount = $self->param('old currency amount');
            if (
                !$old_currency_amount
                || ( $currency_amount
                    && ( $currency_amount ne $old_currency_amount ) )
              )
            {
                my $_sum_in_words =
                  Utils::Digital::sum2ru_words($currency_amount)
                  ;    #TODO: Refactor
                $data->{'currency amount in words'} = $_sum_in_words;
                $self->param( 'currency amount in words' => $_sum_in_words );
            }
            $data->{updater} = Utils::User::current($self);
        }
        else {
            my $_sum_in_words = Utils::Digital::sum2ru_words($currency_amount);
            $data->{'currency amount in words'} = $_sum_in_words;
            $self->param( 'currency amount in words' => $_sum_in_words );
        }

        # check for document number existance
        if (
            Utils::Documents::document_number_exist(
                $self, $data->{'document number'}, $id
            )
          )
        {
            $data->{error} = 1;
            push @{ $data->{errors} }, 'document number already exists';
            $self->stash( document => { 'document number_class' => 'error' } );
        }

        # validate document date
        my $date = Utils::validate_date( $data->{date} );
        if ($date) {
            $data->{date} = $date;
        }
        else {
            $data->{error} = 1;
            push @{ $data->{errors} }, 'invalid date';
            $self->stash( 'date_class' => 'error' );
        }
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
        my $payload = $self->param("payload");
        my $docid   = Utils::Documents::detach($self);
        $self->redirect_to("/documents/update/$payload?docid=$docid");
    }

    sub cancel_update_document_header {
        my $self = shift;

        my $payload = $self->param("payload");
        my $docid   = Utils::Documents::detach($self);
        $self->redirect_to("/documents/update/$payload?docid=$docid");
    }

    sub print {
        my $self = shift;
        return if !$self->who_is( 'local', 'reader' );

        my $docid = $self->param('payload');
        if ($docid) {
            deploy_document( $self, $docid );
        }
    }

    sub add {
        my $self = shift;
        return if !$self->who_is( 'local', 'reader' );

        if ( $self->req->method eq 'POST' ) {
            my $data = validate_new_doc($self);
            if ( $data->{errors_count} ) {
                $self->stash( document => $data );
            }
            else {
                my $db_client = Utils::Db::client($self);

                if ( my $id = $db_client->insert($data) ) {
                    $self->redirect_to(
                        "/documents/update/$id?docid=$id&success=1");
                }
                else {
                    $self->stash( error => 1 );
                    warn 'Could not insert document object!';
                }
            }
        }
        else {
            $self->stash( document => set_new_data($self) );
        }
    }

    sub update {
        my $self = shift;
        return if !$self->who_is( 'local', 'reader' );

        my $isPost = ( $self->req->method =~ /POST/ )
          && ( ( !$self->param('post') )
            || ( $self->param('post') !~ /^preliminary$/i ) );    #???
        my $id      = $self->param('docid');
        my $payload = $self->param('payload');
        my $bt      = $self->param('bt');

        # my $db      = Utils::Db::client($self);
        if ($id) {
            deploy_document( $self, $id );
        }
        else {
            my $template = $self->param('template');
            if ($template) {
                deploy_document( $self, $template );
            }
        }
        set_form_header($self);
        if ($isPost) {

            return if !$self->who_is( 'local', 'writer' );
            my $data = validate_old_doc( $self, $id );
            if ( !exists( $data->{error} ) ) {
                my $db_client = Utils::Db::client($self);
                if ( defined $id ) {
                    if ( $db_client->update($data) ) {
                        $self->stash( success => 1 );
                        $self->redirect_to(
                            "/documents/update/$payload?docid=$id&success=1");
                    }
                    else {
                        $self->stash( error => 1 );
                        warn 'Could not update objects!';
                    }
                }
                else {
                    if ( $id = $db_client->insert($data) ) {
                        $self->redirect_to(
                            "/documents/update/$payload?docid=$id&success=1");
                    }
                    else {
                        $self->stash( error => 1 );
                        warn 'Could not insert document object!';
                    }
                }
            }
            else {
                $self->stash( error => 1 );
            }
        }
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
                for my $field ( keys %{$document} ) {
                    $self->stash( $field => $document->{$field} );
                }
            }
        }
    }

    1;

};

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>


