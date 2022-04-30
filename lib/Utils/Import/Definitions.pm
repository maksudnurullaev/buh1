package Utils::Import::Definitions;
{

=encoding utf8

=head1 NAME

    Different utilites 

=cut

    use 5.012000;
    use strict;
    use warnings;
    use utf8;

    use Utils;
    use Data::Dumper;

    use Utils::Accounts;

    sub import_sasol_definitions {
        my $test_mode = shift || 1;
        open( my $fh, "<", "config/accounts_sasol.txt" )
          or die "cannot open < config/accounts_sasol.txt: $!";

        my $langs_order = shift || [ 'eng', 'rus', 'uzb' ];
        my $result      = {};

        while ( my $line = <$fh> ) {
            if ( $line =~ /^\W*(\d{2})\W(.+)\d{2}\W(.+)/ )
            {    #primary account found
                my $acc_num = $1 . "00";
                $result->{$acc_num} = {
                    $langs_order->[0] => uc( "$acc_num " . Utils::trim($2) ),
                    $langs_order->[1] => uc( "$acc_num " . Utils::trim($3) )
                };
            }
            elsif ( $line =~ /^\W*(\d{4})\W(.+)\d{4}\W(.+)/ ) {  #subconto found
                $result->{$1} = {
                    $langs_order->[0] => ( "$1 " . Utils::trim($2) ),
                    $langs_order->[1] => ( "$1 " . Utils::trim($3) )
                };
            }
        }
        return ($result);
    }

    my $apart_name     = Utils::Accounts::get_account_part_name();
    my $asection_name  = Utils::Accounts::get_account_section_name();
    my $account_name   = Utils::Accounts::get_account_name();
    my $asubconto_name = Utils::Accounts::get_account_subconto_name();

    my $part_id_prefix    = $apart_name . ' ';
    my $section_id_prefix = Utils::Accounts::get_account_section_name() . ' ';

    sub import_lex_definitions {
        my $test_mode = shift || 1;

        open( my $fh, "<", "config/accounts_lex.txt" )
          or die "cannot open < config/accounts_lex.txt: $!";

        my $result = {};
        my ( $current_part, $current_section, $current_account );
        my ( $current_part_num, $current_section_num ) = ( 1, 1 );
        my $restrict = 9;
        while ( ( my $line = <$fh> ) ) {
            utf8::decode($line);
            if ( $line =~ /^ЧАСТЬ/ ) {    #PART
                $restrict--;
                $current_part = $part_id_prefix . ( $current_part_num++ );
                my $part = Utils::trim($line);
                $result->{$current_part} = {
                    rus      => $part,
                    sections => {}
                };
            }
            elsif ( $line =~ /^РАЗДЕЛ/ ) {    #SECTION
                $current_section =
                  $section_id_prefix . ( $current_section_num++ );
                my $section = Utils::trim($line);
                $result->{$current_part}{sections}{$current_section} = {
                    rus      => $section,
                    accounts => {}
                };
            }
            elsif ( $line =~ /^(\d{2}00)\s{4}(\w+.+)\s{4}(\w+)/ ) {    #ACCOUNT
                my ( $acc_num, $acc_name, $acc_type ) = ( $1, $2, $3 );
                $current_account = $acc_num;
                $result->{$current_part}{sections}{$current_section}{accounts}
                  {$current_account} = {
                    type     => Utils::Accounts::get_type($acc_type),
                    rus      => "$acc_num $acc_name",
                    subconto => {}
                  };
            }
            elsif ( $line =~ /^(\d{4})\s{4}(\w+.+)/ ) {                #SUBCONTO
                $result->{$current_part}{sections}{$current_section}{accounts}
                  {$current_account}{subconto}{$1} = { rus => "$1 $2" };
            }
        }
        close($fh) || die "Cannot close file: $!";

        my $sasol = import_sasol_definitions;
        for my $part ( sort keys %{$result} ) {
            my $part_hash = $result->{$part};
            for my $section ( sort keys %{ $part_hash->{sections} } ) {
                my $section_hash = $part_hash->{sections}{$section};
                for my $account ( sort keys %{ $section_hash->{accounts} } ) {
                    my $account_hash = $section_hash->{accounts}{$account};
                    $account_hash->{eng} = $sasol->{$account}{eng}
                      if exists $sasol->{$account}
                      && exists $sasol->{$account}{eng};
                    for
                      my $subconto ( sort keys %{ $account_hash->{subconto} } )
                    {
                        my $subconto_hash =
                          $account_hash->{subconto}{$subconto};
                        $subconto_hash->{eng} = $sasol->{$subconto}{eng}
                          if exists $sasol->{$subconto}
                          && exists $sasol->{$subconto}{eng};
                    }
                }
            }
        }

        for my $part ( sort keys %{$result} ) {
            my $part_hash = $result->{$part};
            warn "\n-> $part: " . $part_hash->{rus};
            my $part_object = {
                object_name => $apart_name,
                id          => $part,
                rus         => $part_hash->{rus}
            };
            for my $section ( sort keys %{ $part_hash->{sections} } ) {
                my $section_hash = $part_hash->{sections}{$section};
                warn "--> $section: " . $section_hash->{rus};
                my $section_object = {
                    object_name => $asection_name,
                    id          => $section,
                    rus         => $section_hash->{rus}
                };
                warn 'Result: ' . Db::update($section_object);
                warn 'Link result: '
                  . Db::set_link( $apart_name, $part, $asection_name,
                    $section );
                for my $account ( sort keys %{ $section_hash->{accounts} } ) {
                    my $account_hash = $section_hash->{accounts}{$account};
                    my $type         = $account_hash->{type};
                    my $account_id   = "$account_name $account";
                    warn "---> $account_hash->{rus} TYPE($type)"
                      if exists $account_hash->{rus};
                    warn "---> $account_hash->{eng} TYPE($type)"
                      if exists $account_hash->{eng};
                    my $account_object = {
                        object_name => $account_name,
                        id          => $account_id,
                        type        => $type,
                        rus         => $account_hash->{rus}
                    };
                    $account_object->{eng} = $account_hash->{eng}
                      if exists $account_hash->{eng};
                    warn "Account result" . Db::update($account_object);
                    warn 'Link result: '
                      . Db::set_link( 'account', $account_id,
                        'account section', $section );

                    for
                      my $subconto ( sort keys %{ $account_hash->{subconto} } )
                    {
                        warn "----> $account_hash->{subconto}{$subconto}{rus}"
                          if exists $account_hash->{subconto}{$subconto}{rus};
                        warn "----> $account_hash->{subconto}{$subconto}{eng}"
                          if exists $account_hash->{subconto}{$subconto}{eng};
                        my $subconto_id     = "$asubconto_name $subconto";
                        my $subconto_object = {
                            object_name => $asubconto_name,
                            id          => $subconto_id,
                            type        => $type,
                            rus => $account_hash->{subconto}{$subconto}{rus}
                        };
                        $subconto_object->{eng} =
                          $account_hash->{subconto}{$subconto}{eng}
                          if exists $account_hash->{subconto}{$subconto}{eng};
                        warn "Subconto result: " . Db::update($subconto_object);
                        warn "Link result: "
                          . Db::set_link(
                            $asubconto_name, $subconto_id,
                            $account_name,   $account_id
                          );
                    }
                }
            }
        }
        return ($result);
    }

};

1;

__END__

=head1 AUTHOR

 M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
