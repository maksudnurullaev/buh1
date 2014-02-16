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
     my $data = { object_name => $self->param('oname'),
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
    my $data = { object_name => $self->param('oname'),
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


# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

 M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
