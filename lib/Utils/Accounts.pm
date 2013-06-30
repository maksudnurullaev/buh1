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
use Hash::Merge::Simple qw/ merge /;
use utf8;

my ( $ACCOUNT_PART ,$ACCOUNT_SECTION ,$ACCOUNT ,$ACCOUNT_SUBCONTO , $TYPES )
 = ( 'account part','account section','account','account subconto', ['a','p','ca','cp','t'] );

sub get_part_name{
    return($ACCOUNT_PART);
};

sub get_account_name{
    return($ACCOUNT);
};

sub normalize_local{
    my($hashref,$langs,$lang) = @_;
    return(undef) if !$hashref || !$langs || !$lang ;
    for my $key (keys %{$hashref}){
        if( ref $hashref->{$key} eq 'HASH' ){
            normalize_local($hashref->{$key},$langs,$lang);
        }
    }
    my $found = 0;
    if ( exists($hashref->{$lang}) && 
         $hashref->{$lang} ){
        $hashref->{name} = $hashref->{$lang}
    }else{
        my @result = ();
        my @names = ("-$lang");
        for my $name (@{$langs}){
            if($name ne $lang && exists($hashref->{$name})){
                push @names, "+$name"; 
                push @result, $hashref->{$name};
            }
        }

        $hashref->{name} = 
            '[' . join('/',@names) . '] ' . join('/',@result)
            if @result; 
    }
};

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

sub get_child_name_by_id{
    my $id = shift;
    if( $id ){
        my $objects = Db::get_objects({id=>[$id]});
        return get_child_name($objects->{$id}{object_name}) if $objects;
    }
    return(undef);
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
    return(Db::get_links($section_id,$ACCOUNT));
};

sub get_subcontos{
    my $account_id = shift;
    if( $account_id ) {
        return(Db::get_links($account_id,$ACCOUNT_SUBCONTO,['rus','eng','uzb']));
    }
};

sub get_account_by_numeric_id{
    my $parameter_string = shift;
    return(undef) if( !$parameter_string );
    my $id_selection;
    if( $parameter_string =~ /,/  && $parameter_string !~ /-/ ){
        $id_selection = [map { "account subconto $_" } split /,/,$parameter_string];
    }elsif( $parameter_string =~ /,/  && $parameter_string =~ /-/ ){
        my @list = split /,/, $parameter_string;
	my @result = ();
	for my $id_temp (@list){
            if( $id_temp =~ /-/ ){
                $id_selection = ['between', map { "account subconto $_" } split( /-/, $parameter_string)];
                push @result, Db::get_objects({ id => $id_selection });
            }else{
	        push @result, Db::get_objects({ id => ["account subconto $id_temp"});
            }
        }
        my $result_hash = {};
        for $hash_temp (@result){
            $result_hash = Hash::Merge::Simple::merge($result,$hash_temp);
        }
        warn Dumper $result_hash;
        return($result_hash);
    }elsif ( $parameter_string =~ /-/ ) {
        $id_selection = ['between', map { "account subconto $_" } split( /-/, $parameter_string)];
    } else {
        $id_selection = ["account subconto $parameter_string"];
    }
    return Db::get_objects({ id => $id_selection });
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
