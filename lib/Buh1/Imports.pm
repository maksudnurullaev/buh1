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
use Utils::Imports;

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

sub parse_operations_lex {
    my ( $self, $dom, $result ) = ( shift, shift, {} );
    if ( !$self || !$dom ) { warn "Empty parameters!"; return; }

    my ( $start_parse_tds, $current_code ) = ( 0, undef );
    for my $div ( $dom->find('div')->each ) {
        if (!$start_parse_tds) {   # search operations header
                my ( $class, $text ) = (
                    $div->attr('class'), Utils::Imports::get_dom_deep_text($div)
                );
                if (   $class
                    && $text
                    && uc($class) eq 'TEXT_HEADER_DEFAULT'
                    && $text =~ /\((\d{4})\)/ )
                {
                    $start_parse_tds    = 1;
                    $result->{$1}{name} = $text;
                    $current_code       = $1;
                    $start_parse_tds    = 1;
                    warn "$start_parse_tds" if $debug_mode;
                    next;
                }
        } elsif( $start_parse_tds) {    #search operations descriptions
                my ( $class, $id ) = ( $div->attr('class'), $div->attr('id') );
                warn "( $class, $id )" if $class && $id && $debug_mode;
                if (   $class
                    && $id
                    && uc($class) eq "TABLE_STD"
                    && uc($id) eq uc("theDefCssID") )
                {
                    my $oper_desc_trs = $div->find('tr');
                    $result->{$current_code}{size} = $oper_desc_trs->size;
                    $result->{$current_code}{operations} =
                      parse_operations_desc_trs($oper_desc_trs);
                    warn "Found tr's: " . $div->find('tr')->size if $debug_mode;
                    $start_parse_tds = 0;
                    warn "$start_parse_tds" if $debug_mode;
                    next;
                }

        } else {
                warn "Not definde case of start_parse_tds: $start_parse_tds";
        }
    }
    return $result;
}

sub parse_operations_desc_trs {
    my $trs = shift;
    if ( !$trs || !$trs->size ) {
        warn "Nothing to parse: oprations descriptions";
        return;
    }

    my $result = {};
    for my $TR ( $trs->each ) {
        my $TDs = $TR->find('td');
        if ( $TDs->size == 4
            && Utils::Imports::get_dom_deep_text( $TDs->[0] ) =~ /(\d+)\./ )
        {
            my ( $desc_N, $desc_text, $desc_D, $desc_C ) = (
                $1,
                Utils::Imports::get_dom_deep_text( $TDs->[1] ),
                Utils::Imports::get_dom_deep_text( $TDs->[2] ),
                Utils::Imports::get_dom_deep_text( $TDs->[3] )
            );
            $result->{"operation_$1"} = {
                desc   => $desc_text,
                debet  => $desc_D,
                credit => $desc_C
            };
            warn "($desc_N, $desc_text, $desc_D, $desc_C)" if $debug_mode;
        }
    }
    warn "Result size: " . scalar( keys %{$result} ) if $debug_mode;
    return $result;
}

sub parse_accounts_lex {
    my ( $self, $dom, $result ) = ( shift, shift, {} );
    if ( !$self || !$dom ) { warn "Empty parameters!"; return; }

    my ( $current_part, $current_section, $current_account );
    my ( $current_part_num, $current_section_num ) = ( 1, 1 );

    for my $div ( $dom->find('div[class="TABLE_STD"]')->each ) {
        my $TRs = $div->find('tr[tabindex="1"]');
        for my $TR ( $TRs->each ) {
            my $TDs = $TR->find('td');

            if (
                $TDs->size == 1
                && ( my $text = Utils::Imports::get_dom_deep_text( $TDs->[0] ) )
              )
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
                && ( $text = Utils::Imports::get_dom_deep_text( $TDs->[0] ) ) )
            {
                if ( $text =~ /^\d{2}00/ ) {    # ... ACCOUNTs
                    my ( $name, $type ) = (
                        Utils::Imports::get_dom_deep_text( $TDs->[1] ),
                        Utils::Imports::get_dom_deep_text( $TDs->[2] )
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
                    my $name = Utils::Imports::get_dom_deep_text( $TDs->[1] );
                    next                     if !$name;
                    warn ".... $text $name " if $debug_mode;
                    $result->{$current_part}{sections}{$current_section}
                      {accounts}{$current_account}{subconto}{$text} =
                      { rus => "$text $name" };
                }
                elsif ( $text =~ /^\d{3}/ ) {    # off-balance
                    my $name = Utils::Imports::get_dom_deep_text( $TDs->[1] );
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
                my $result = parse_accounts_lex( $self, $html_dom_all );
                $self->stash( parts => $result );
            }
            elsif ( $req_params->{parse_variant} eq 'operations' ) {
                my $result = parse_operations_lex( $self, $html_dom_all );
                $self->stash( operations => $result );
            }
            else { warn "Not defined parse variant!"; }
        }
        else {
            warn "URL: !!!NOT VALID!!!" if $debug_mode;
        }

    }

}

# END OF PACKAGE

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
