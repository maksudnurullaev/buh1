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
use Data::Dumper;
use utf8;

# PARENT <-> CHILD LINKS
# ACOUNT PART 
# └─► ACCOUNT SECTION 
#       └─► ACCOUNT 
#            └─► ACCOUNT SUBCONTO

our ( $ACCOUNT_PART ,$ACCOUNT_SECTION ,$ACCOUNT ,$ACCOUNT_SUBCONTO , $TYPES )
 = ( 'account part','account section','account','account subconto', ['a','p','ca','cp','t'] );

sub get_part_name{
    return($ACCOUNT_PART);
};

sub get_account_name{
    return($ACCOUNT);
};

sub authorized2modify{
    my $self = shift ;
    if( !$self->who_is_global('editor') ){
        $self->redirect_to('/user/login?warning=access');
        return(0);
    }
    return(1);
};

sub validate4add_part{
    my $self = shift;
    my $data =  validate($self,['rus','id'],['eng','uzb','type']);
    if ( $data->{id} !~ /^\d+$/ ){
        $data->{error} = 1 ; 
        $self->stash('id_class' => 'error');
        warn "Accounts:validate4add_part: id is not numeric!";
    } else {
        my $parent_id = "$data->{object_name} $data->{id}";
        my $db = Db->new($self);
        if( $db->get_objects({id => [$parent_id]}) ){
            $data->{error} = 1 ;
            warn "Accounts:validate4add_part: such object already exists!";
        }
    }
    return($data);
};

sub validate{
    my ($self,$mandatories,$optionals) = @_;
    my $data = { 
        object_name => $self->param('object_name'),
        updater => Utils::User::current($self) };
    for my $field (@{$mandatories}){
        $data->{$field} = Utils::trim $self->param($field);
        if ( !$data->{$field} ){
            $data->{error} = 1 ;
            $self->stash(($field . '_class') => 'error');
        }
    }
    for my $field (@{$optionals}){
        $data->{$field} = $self->param($field) if $self->param($field);
    }
    return($data);
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
    my ($self, $id) = @_ ;
    if( $id ){
        my $db = Db->new($self);
        my $objects = $db->get_objects({id=>[$id]});
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
    my $db = Db->new(shift);
    return($db->get_objects( { name =>  [$ACCOUNT_PART] } ));
};

sub get_sections{
    my $self    = shift;
    my $part_id = shift;
    return(undef) if !$part_id;
    my $db = Db->new($self);
    return($db->get_links($part_id,$ACCOUNT_SECTION,['rus','eng','uzb']));
};

sub get_accounts{
    my $self       = shift;
    my $section_id = shift;
    return(undef) if !$section_id;
    my $db = Db->new($self);
    return($db->get_links($section_id,$ACCOUNT));
};

sub get_subcontos{
    my $self       = shift;
    my $account_id = shift;
    if( $account_id ) {
        my $db = Db->new($self);
        return($db->get_links($account_id,$ACCOUNT_SUBCONTO,['rus','eng','uzb']));
    }
};

sub get_account_by_numeric_id{
    my $self             = shift;
    my $parameter_string = shift;
    return(undef) if( !$parameter_string );
    my $id_selection;
    my $db = Db->new($self);
    if( $parameter_string =~ /,/  && $parameter_string !~ /-/ ){
        $id_selection = [map { "account subconto $_" } split /,/,$parameter_string];
    }elsif( $parameter_string =~ /,/  && $parameter_string =~ /-/ ){
        my @list = split /,/, $parameter_string;
        my @result = ();
        for my $id_temp (@list){
            if( $id_temp =~ /-/ ){
                $id_selection = ['between', map { "account subconto $_" } split( /-/, $id_temp)];
                push @result, $db->get_objects({ id => $id_selection });
            }else{
                push @result, $db->get_objects({ id => ["account subconto $id_temp"]});
            }
        }
        my $result_hash = {};
        for my $hash_temp (@result){
            $result_hash = Hash::Merge::Simple::merge($result_hash,$hash_temp);
        }
        return($result_hash);
    }elsif ( $parameter_string =~ /-/ ) {
        $id_selection = ['between', map { "account subconto $_" } split( /-/, $parameter_string)];
    } else {
        $id_selection = ["account subconto $parameter_string"];
    }
    return $db->get_objects({ id => $id_selection });
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
