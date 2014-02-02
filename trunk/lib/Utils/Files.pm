package Utils::Files; {

=encoding utf8

=head1 NAME

    Files utilites 

=cut

use 5.012000;
use strict;
use warnings;
use utf8;
use Data::Dumper;

sub add_file4id{
	my ($self,$new_file,$id) = @_ ;
	my $client_id = $self->session('company id') ;

	my $path      = Utils::get_root_path(get_path($self,$id));
	system "mkdir -p '$path/'" if ! -d $path ;

	my $path_file = "$path/" . $new_file->filename;
	$new_file->move_to($path_file);
};

sub get_path{
	my($self,$id) = @_ ;
	my $client_id = $self->session('company id') ;
	return( "db/clients/$client_id/$id" ) ;
};

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

 M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
