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
    warn $eval_string ;
    my $result = calculate($eval_string);
    if( $result ){
        $self->stash( result => $result );
    } else {    
        $self->stash( result_error => $eval_string );
    }
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
            warn "X" . ('X' x $recursion ) . " $_" ;
            my $value = $data->{"f_value$_"} ;
            warn "Z" . ('Z' x $recursion ) . " $value" ;
            if( $value =~ /_\d+/ ){
                $value = encode_eval_string($self,$data,$value,++$recursion);
                $eval_string =~ s/$_/$value/g;
                if( !exists($data->{"f_calculated_value$_"}) ){
                    $self->stash("f_calculated_value$_" => calculate($value)) ;
                }
            } else {
                $eval_string =~ s/$_/$value/g;
            }
        }
    }
    --$recursion ;
    warn "RESULT: $eval_string" ;
	return("( $eval_string )" ) ;
};

sub calculate{
    my $eval_string = shift ;
    return(undef) if !$eval_string ;
    my $result = eval($eval_string) ;
    if( $@ ) { # some error in eval
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
