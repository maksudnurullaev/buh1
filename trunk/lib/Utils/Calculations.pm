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

sub add{
    my $self = shift ;
    if( lc($self->param('controller')) ne 'calculatons' ){
        return if !$self->who_is('local','writer');
        return(add_client_calc($self));
    } else {
        return if !$self->who_is('global','editor');
        return(add_global_calc($self));
    }
};

sub add_global_calc{
    my $self = shift ;
    my $data = form2data($self);
    my $path = $self->param('path');
    if( validate($self,$data) ){
        Utils::Db::db_insert_or_update($self,$data);
        $self->redirect_to(Utils::url_append($path, 'success=1'));
    } else {
        $self->redirect_to(Utils::url_append($path, 'error=1'));
    }
};

sub add_client_calc{
    my $self = shift ;
    my $pid  = $self->param('pid');
    my $path = $self->param('path');
    if ( $self->req->method =~ /POST/ ){
        my $data = form2data($self);
        if( validate($self,$data) ){
            if( defined $self->param('use_template') ){
                my $cid = $self->param('calculation_template');
                $data = merge_calcs($self,$data,$cid); 
            }
            my $dbc = Utils::Db::client($self);
            my $cid = $dbc->insert($data);
            $dbc->set_link($pid,$cid);
            $self->redirect_to(Utils::url_append($path, 'success=1'));
        } else {
            $self->redirect_to(Utils::url_append($path, 'error=1'));
        }
    }
};

sub merge_calcs{
    my ($self,$data,$cid) = @_;
    return($data) if !$self || !$data || !$cid ;
    my $db = Utils::Db::main($self);
    my $template = $db->get_objects({ id => [$cid] })->{$cid} ;
    for my $del_key (qw/id description creator object_name/){
        delete $template->{$del_key};
    }
    for my $key (keys %{$template}){
        $data->{$key} = $template->{$key} ;
    }
    return($data);    
};

sub get_client_calcs{
    my ($self,$pid) = @_;
    return(undef) if !$self->who_is('local','reader');
    my $dbc = Utils::Db::client($self);
    return( $dbc->get_links($pid,'calculation',['description']) );
};

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
    $eval_string = decode_eval_string($self, $data, $eval_string);
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
    my $guide_map = Utils::Guides::decode_guide_content($Buh1::my_self, $guide_num);
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
        $eval_string = decode_eval_string($self, $data, $eval_string) ;
        $self->stash( eval_string => $eval_string );
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
        $eval_string = decode_eval_string($self, $data, $eval_string) ;
        return( calculate($eval_string) );
    }
    return(undef);
};

sub decode_eval_string{
    my $self        = shift ;
    my $data        = shift ;
    my $eval_string = shift ;
    return(undef) if !$eval_string ;

    my $recursion   = shift || 0 ;
    return "ERROR:RECURSION: $recursion" if $recursion > 10 ;

    for ( $eval_string =~ m/(_\d+)/g ){
        if( exists($data->{"f_value$_"}) && $data->{"f_value$_"} ){ 
            my $value = $self->stash("f_calculated_value_$_") || $data->{"f_value$_"} ;
            $eval_string =~ s/$_\b/$value/g;
        }
    }
   if( $eval_string =~ /_\d/ ){
        $eval_string = decode_eval_string($self,$data,$eval_string,++$recursion);
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


