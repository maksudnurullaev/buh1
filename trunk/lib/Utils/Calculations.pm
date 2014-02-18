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
				  id          => $self->param('payload'),
				  calculation => ($self->param('calculation') || "_1") } ;
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
    my $calculation = $data->{calculation};
    for my $key (keys %{$data}){
        if( $key =~ /f_value(_\d+)/ ){
            my $value = $data->{$key} ;
            $calculation =~ s/$1/$value/g ;
        }
    }
    $self->stash( result => eval($calculation) ) if $calculation ;
    if( $@ ) { # some error in eval
        $self->stash( result_error => $calculation );
        warn $@ ;
    }
}; 

sub get_db_list{
    my $self = shift;
    return(Utils::Db::db_get_objects($self,{name=>['calculation'], field => ['description']}));
};

sub get_list_as_select_data{
    my $self = shift ;
    my $data = shift ;
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

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

 M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
