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
    while( $self->param("f_description_$field_index") ) {
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
	
	$data->{id} = $self->param('payload') if $self->param('payload') ;
    $data->{description} = Utils::trim $self->param('description')
        if Utils::trim $self->param('description');
    return($data)
};

sub validate{
    my ($self,$data) = @_ ;
    if( !exists $data->{description} ){
        $self->stash('description_class' => 'error');
        $self->stash('error' => 1);
        return(0);
    }
    return(1);
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

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

 M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
