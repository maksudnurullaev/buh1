package Utils::Calculations; {

=encoding utf8

=head1 NAME

    Database utilites 

=cut

use 5.012000;
use strict;
use warnings;
use utf8;
use Utils::Db;
use Utils::Guides ;
use Data::Dumper;

sub form2data_fields{
    my $self = shift;
    my $data = { object_name => 'calculation',
				 id          => $self->param('id'),
				 calculation => ($self->param('calculation') || '_1') } ;
    my $field_index = 1 ;
    while( $self->param("f_description_$field_index") ){
 		$data->{ "f_description_$field_index" } = $self->param("f_description_$field_index") ;
 		$data->{ "f_value_$field_index" } = $self->param("f_value_$field_index") ;
 	    $field_index++ ;
    }
    return($data);
};

sub form2data{
    my $self = shift;
    my $data = { object_name => 'calculation',
		         creator     => Utils::User::current($self) } ;
	
	$data->{id} = $self->param('id') if $self->param('id') ;
    $data->{description} = Utils::trim $self->param('description')
        if Utils::trim $self->param('description');
    return($data)
};

sub validate{
    my ($self,$data) = @_ ;
    return( exists $data->{description} );
};

sub deploy_result{
    my ($self,$data) = @_ ;
    my $eval_string = $data->{calculation} ;
    $eval_string = encode_eval_string($self, $data, $eval_string);
    my $result = calculate($eval_string);
    if( $result ){
        $self->stash( result => $result );
    } else {    
        $self->stash( result_error => $eval_string );
    }
};

sub spravka{
    my($guide_num,$col2search,$val2search,$col2return,$default_result) = @_;
    if(!(defined($guide_num) && defined($col2search) && defined($val2search) && defined($col2return))){
        $guide_num  = $guide_num  || 'NaN';
        $col2search = $col2search || 'NaN';
        $val2search = $val2search || 'NaN';
        $col2return = $col2return || 'NaN';
        warn "spravka($guide_num,$col2search,$val2search,$col2return)?";
        return("spravka($guide_num,$col2search,$val2search,$col2return)?"); 
    }
    # 1. find guide
    $default_result = $default_result || 'NaN';
    my $guide_map = Utils::Guides::decode_guide_content($guide_num);
    for my $key(keys %{$guide_map->{data}}){
        my $row = $guide_map->{data}{$key};
        my $row_length = scalar(@{$row});
        continue if $col2search > $row_length;
        if( $val2search =~ /^\d+/ ){
            if( $row->[($col2search - 1)] == $val2search ){
                if($col2return < $row_length){
                    return($row->[($col2return - 1)]);
                }
            }
        } else {
            if( $row->[($col2search - 1)] eq $val2search ){
                if($col2return < $row_length){
                    return($row->[($col2return - 1)]);
                }
            }
        }    
    }
    return($default_result);
};

sub db_calculate{
    my( $self,$id ) = @_ ;
    my $objects = Utils::Db::db_get_objects($self, { id => [$id] });
    if( $objects ){
        my $data = $objects->{$id} ;
        my $eval_string = $data->{calculation} ;
        $eval_string = encode_eval_string($self, $data, $eval_string) ;
        return( calculate($eval_string) );
    }
    return(undef);
};

sub cdb_calculate{
    my( $self,$id ) = @_ ;
    my $objects = Utils::Db::cdb_get_objects($self,{ id => [$id] });
    if( $objects ){
        my $data = $objects->{$id} ;
        my $eval_string = $data->{calculation} ;
        $eval_string = encode_eval_string($self, $data, $eval_string) ;
        return( calculate($eval_string) );
    }
    return(undef);
};

sub encode_eval_string{
    my $self        = shift ;
    my $data        = shift ;
    my $eval_string = shift ;
    return(undef) if !$eval_string ;

    my $recursion   = shift || 0 ;
    return "ERROR:RECURSION: $recursion" if $recursion > 10 ;

    for ( $eval_string =~ m/(_\d+)/g ){
        if( exists($data->{"f_value$_"}) && $data->{"f_value$_"} ){ 
            my $value = $data->{"f_value$_"} ;
            if( $value =~ /_\d+/ ){
                $value = encode_eval_string($self,$data,$value,++$recursion);
                $eval_string =~ s/$_/$value/g;
                if( !exists($data->{"f_calculated_value$_"}) ){
                    $self->stash("f_calculated_value$_" => calculate($value)) ;
                }
            } else {
                $eval_string =~ s/$_\b/$value/g;
            }
        }
    }
    --$recursion ;
	return("( $eval_string )" ) ;
};

sub calculate{
    my $eval_string = shift ;
    return(undef) if !$eval_string ;
    my $result = eval($eval_string) ;
    if( $@ ) { # some eror in eval
        warn $@ ;
        return(undef);
    }
    return($result);
};

sub get_db_list{
    my $self = shift;
    return(Utils::Db::db_get_objects($self,{name=>['calculation'], field => ['description']}));
};

sub get_list_as_select_data{
    my $self = shift ;
    my $data = shift ;
	return(undef) if !scalar(keys(%{$data})) ;
    my $result = [];
    for my $key (reverse sort keys %{$data}){
        my $description = $data->{$key}{description};
        $description = substr($description, 0, 20) 
            . '...' 
            . substr($description, -5, 5) if length($description) > 30 ; 
        push @{$result}, [ $description => $key ] ;
    }
    return($result);
};

sub count{
    my($self,$id) = @_ ;
    my $dbc = Utils::Db::client($self);
    return(0) if !$dbc ;
    my $calculations = $dbc->get_links($id,'calculation',['description']);
	return(0) if !$calculations ;
	return(scalar(keys(%{$calculations}))) ;
};

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

 M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
