package Utils::Documents;
{

=encoding utf8

=head1 NAME

    Documents utilites 

=cut

    use 5.012000;
    use strict;
    use warnings;
    use utf8;
    use Data::Dumper;
    use DbClient;
    use Utils::Db;

    sub attach {
        my ( $self, $docid ) = @_;
        return if !$docid;
        my $db = Utils::Db::client($self);
        return if !$db;

        my $objects = $db->get_objects(
            {
                id    => [$docid],
                field => [ 'document number', 'currency amount', 'details' ]
            }
        );
        return (undef) if !$objects;
        my $document = $objects->{$docid};
        $self->session( docid    => $docid );
        $self->session( document => $document );
    }

    sub detach {
        my $self  = shift;
        my $docid = $self->session->{docid};

        delete $self->session->{docid};
        delete $self->session->{document};
        return ($docid);
    }

    sub get_document_number_next {
        my $self                 = shift;
        my $document_number_last = get_document_number_last($self);
        return ('1')               if !$document_number_last;
        return ( $` . ( $& + 1 ) ) if ( $document_number_last =~ /(\d+)$/ );
        return ("$document_number_last.1");
    }

    sub get_document_number_last {
        my $self = shift;
        my $db   = Utils::Db::client($self);
        my $sth  = $db->get_from_sql(
"SELECT value FROM objects WHERE name = 'document' AND field='document number' AND id=(SELECT MAX(id) FROM objects WHERE name='document');"
        );
        if ( $sth && ( my $result = $sth->fetch() ) ) {
            return $result->[0] if $result && $result->[0];
        }
        return (undef);
    }

    sub document_number_exist {
        my $self            = shift;
        my $document_number = shift;
        my $document_id     = shift;
        return (1) if !$document_number;

        my $db = Utils::Db::client($self);
        my $sql_string =
" SELECT value FROM objects WHERE name = 'document' AND field='document number' AND value=? ";
        my $sth;
        if ($document_id) {
            $sql_string .= " AND id!=? ";
            $sth =
              $db->get_from_sql( $sql_string, $document_number, $document_id );
        }
        else {
            $sth = $db->get_from_sql( $sql_string, $document_number );
        }
        if ( $sth && ( my $result = $sth->fetch() ) ) {
            return $result->[0] if $result && $result->[0];
        }
        return (undef);
    }

    sub get_tbalance_data {
        my ( $self, $start_date, $end_date ) = @_;
        my $result_where;
        if ($end_date) {
            $result_where = " value <= '$end_date' ";
        }
        else {
            return (undef);
        }
        my $sql_string =
            " SELECT * FROM objects WHERE "
          . " field IN ('debet','credit','currency amount','date','details','document number','account') "
          . " AND "
          . " id IN (SELECT DISTINCT id FROM objects WHERE name = 'document' "
          . " AND field = 'date' AND $result_where ); ";
        my $data   = Utils::Db::cdb_get_objects_from_sql( $self, $sql_string );
        my $result = generate_tbalance_data( $self, $data, $start_date );
        return ( ( $result, $data ) );
    }

    sub generate_tbalance_data {
        my ( $self, $data, $date1 ) = @_;
        return (undef) if !$self || !$data || !$date1;
        my $tbalance = {};
        for my $doc_id ( keys %{$data} ) {
            my $debet         = $data->{$doc_id}{debet};
            my $debet_code    = get_account_code( $data->{$doc_id}{debet} );
            my $credit        = $data->{$doc_id}{credit};
            my $credit_code   = get_account_code( $data->{$doc_id}{credit} );
            my $amount        = $data->{$doc_id}{'currency amount'};
            my $is_start_part = ( $date1 ge $data->{$doc_id}{date} );

            generate_tbalance_row( $self, $tbalance, $debet_code, 'debet',
                $amount, $is_start_part, $doc_id );
            generate_tbalance_row( $self, $tbalance, $credit_code, 'credit',
                $amount, $is_start_part, $doc_id );
        }
        generate_tbalance_totals( $self, $tbalance );
        return ($tbalance);
    }

    sub generate_tbalance_totals {
        my ( $self, $tbalance ) = @_;
        return if !$tbalance;
        my ( $start_debets, $start_credits, $debets, $credits, $end_debets,
            $end_credits )
          = ( 0, 0, 0, 0, 0, 0 );
        my $lang = Utils::Languages::current($self);
        my $rows = $tbalance->{rows};
        for my $key ( sort keys %{$rows} ) {
            my ( $sd, $sc, $d, $c ) = ( 0, 0, 0, 0 );
            my $account_id = $rows->{$key}{account_id};
            my $account =
              Utils::Db::db_get_objects( $self,
                { id => [$account_id], field => [ 'type', $lang ] } )
              ->{$account_id};
            $rows->{$key}{name} = $account->{$lang};
            $rows->{$key}{type} = $account->{type};

            $sd = $rows->{$key}{start_debet}  || 0;
            $sc = $rows->{$key}{start_credit} || 0;
            $d  = $rows->{$key}{debet}        || 0;
            $c  = $rows->{$key}{credit}       || 0;

            #warn "(\$sd,\$sc,\$d,\$c) = ($sd,$sc,$d,$c)";
            my ( $start_debet, $start_credit, $debet, $credit, $end_debet,
                $end_credit )
              = tbalance_row( $self, $account->{type}, $sd, $sc, $d, $c );

#warn "(\$start_debet,\$start_credit,\$debet,\$credit,\$end_debet,\$end_credit) = ($start_debet,$start_credit,$debet,$credit,$end_debet,$end_credit)"
            $rows->{$key}{start_debet} = $start_debet;
            $start_debets += $start_debet;
            $rows->{$key}{start_credit} = $start_credit;
            $start_credits += $start_credit;
            $rows->{$key}{debet} = $debet;
            $debets += $debet;
            $rows->{$key}{credit} = $credit;
            $credits += $credit;
            $rows->{$key}{end_debet} = $end_debet;
            $end_debets += $end_debet;
            $rows->{$key}{end_credit} = $end_credit;
            $end_credits += $end_credit;
        }
        $tbalance->{totals}                = {};
        $tbalance->{totals}{start_debets}  = $start_debets;
        $tbalance->{totals}{start_credits} = $start_credits;
        $tbalance->{totals}{debets}        = $debets;
        $tbalance->{totals}{credits}       = $credits;
        $tbalance->{totals}{end_debets}    = $end_debets;
        $tbalance->{totals}{end_credits}   = $end_credits;
    }

    sub generate_tbalance_row {
        my ( $self, $tbalance, $code, $code_name, $amount, $is_start_part,
            $doc_id )
          = @_;
        $tbalance->{rows} = {} if !exists $tbalance->{rows};
        my $rows       = $tbalance->{rows};
        my $account_id = "account $code" . '00';
        my $with_details =
          $self->param('account') && ( $account_id eq $self->param('account') );
        $code_name = "start_$code_name" if $is_start_part;
        if ( !exists( $rows->{$code} ) ) {
            $rows->{$code}             = {};
            $rows->{$code}{account_id} = "account $code" . '00';
            $rows->{$code}{$code_name} = $amount;
        }
        else {
            $rows->{$code}{$code_name} += $amount;
        }

        # row details
        if ( !exists( $rows->{$code}{docs} ) ) {
            $rows->{$code}{docs} = { $doc_id => { $code_name => $amount } };
        }
        else {
            $rows->{$code}{docs}{$doc_id} = { $code_name => $amount };
        }
    }

    sub get_account_code {
        my $account_id = shift;
        if ( $account_id =~ /subconto/ ) {
            return $1 if $account_id =~ /subconto\s(\d\d)/;
        }
        else {
            return $1 if $account_id =~ /account\s(\d\d)/;
        }
        return (undef);
    }

    sub tbalance_row {
        my $self         = shift;
        my $account_type = shift || 0;
        my $start_debet  = shift || 0;
        my $start_credit = shift || 0;
        my $debet        = shift || 0;
        my $credit       = shift || 0;
        if ( $account_type =~ /^[a|ca]/ ) {    # active account
            $start_debet -= $start_credit;
            my $end_debet = $start_debet + $debet - $credit;
            return ( $start_debet, 0, $debet, $credit, $end_debet, 0 );
        }
        $start_credit -= $start_debet;
        my $end_credit = $start_credit + $credit - $debet;
        return ( 0, $start_credit, $debet, $credit, 0, $end_credit );
    }

    # END OF PACKAGE
};

1

__END__

=head1 AUTHOR

 M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
