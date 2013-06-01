package Utils::Accounts; {

=encoding utf8

=head1 NAME

    Different utilites 

=cut

use 5.012000;
use strict;
use warnings;
use utf8;

use Db;
use Utils;
use utf8;

my ($ACCOUNT_PART,$ACCOUNT_SECTION,$ACCOUNT,$ACCOUNT_SUBCONTO, $TYPES)
        = ('account part','account section','account','account subconto', ['a','p','ca','cp','t']);

sub get_types4select{
    my $self = shift;
    my $selected_value = shift;
    my $result = [];
    for my $t (@{$TYPES}){
        if( $selected_value && $selected_value eq $t ){
            push @{$result}, [$self->ml("account type $t") => $t, selected => 'true'];
        } else {
            push @{$result}, [$self->ml("account type $t") => $t];
        }
    }
    return($result);
};

sub get_child_name{
    my $account_name = shift;
    return(undef) if !$account_name;
    return($ACCOUNT_SECTION)  if($account_name eq $ACCOUNT_PART);
    return($ACCOUNT)          if($account_name eq $ACCOUNT_SECTION);
    return($ACCOUNT_SUBCONTO) if($account_name eq $ACCOUNT);
    return(undef);
};

sub get_parent_name{
    my $account_name = shift;
    return(undef) if !$account_name;
    return($ACCOUNT_PART)    if($account_name eq $ACCOUNT_SECTION);
    return($ACCOUNT_SECTION) if($account_name eq $ACCOUNT);
    return($ACCOUNT)         if($account_name eq $ACCOUNT_SUBCONTO);
    return(undef);
};

sub get_all_parts{
    return(Db::get_objects( { name =>  [$ACCOUNT_PART] } ));
};

sub get_sections{
    my $part_id = shift;
    return(undef) if !$part_id;
    return(Db::get_links($part_id,$ACCOUNT_SECTION,['rus','eng','uzb']));
};

sub get_accounts{
    my $section_id = shift;
    return(undef) if !$section_id;

    return(Db::get_links($section_id,$ACCOUNT,['type','rus','eng','uzb']));
};

sub get_subcontos{
    my $account_id = shift;
    if( $account_id ) {
        return(Db::get_links($account_id,$ACCOUNT_SUBCONTO,['rus','eng','uzb']));
    }
};

sub get_type{
    my $type_local = shift;
    return(undef) if !$type_local;
    if( $type_local =~ /^А/i ){         # активный       счет
        return('a');
    }elsif ( $type_local =~ /^П/i ){    # пассивный      счет
        return('p');
    }elsif ( $type_local =~ /^КА/i ){   # контрактивный  счет
        return('ca');
    }elsif ( $type_local =~ /^КП/i ){   # контрпассивный счет
        return('cp');
    }elsif ( $type_local =~ /^Т/i ){    # транзитный     счет
        return('t');
    }elsif ( $type_local =~ /^З/i ){    # забалансовый   счет
        return('z');
    }
    return(undef);
};

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
