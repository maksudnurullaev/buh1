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

sub file_list4id{
	my ($self,$id) = @_ ;
	my $client_id = $self->session('company id') ;

	my $path = Utils::get_root_path(get_path($self,$id));
    warn $path ;
	if( ! -d $path ){
        system "mkdir -p '$path/'" ;
        return ;
    }
    
    my $dir;
    opendir($dir, $path);
	my $result = {};
    while (my $file = readdir($dir)) {
        next if ($file =~ m/^\./) || ($file =~ /\.description$/);
		$result->{ $file } = get_file_description("$path/$file") ;
    }
    closedir($dir);
	return($result);
};

sub get_file_description{
	my $file_path = shift;
	return(undef) if !$file_path ;
	my $description_file = $file_path . '.description' ;
	if( -e $description_file ){
		return get_file_content($description_file);
	}
	return(undef);
};

sub get_file_content{
	my $file_path = shift;
	return(undef) if !$file_path ;
	if( -e $file_path ){
		my($fh,$content);
		if( open(my $fh, "< :encoding(UTF-8)", $file_path) ){
			$content = do { local $/; <$fh> }; 
			close($fh);
			return($content)
		} else {
			warn $! ;
		}
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
