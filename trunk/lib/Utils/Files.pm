package Utils::Files; {

=encoding utf8

=head1 NAME

    Files utilites 

=cut

use 5.012000;
use strict;
use warnings;
use utf8;
use Utils;
use Data::Dumper;

sub add_file4id{
	my ($company_id,$id,$new_file,$file_description) = @_ ;
	my $path      = Utils::get_root_path(get_path($company_id,$id));
	system "mkdir -p '$path/'" if ! -d $path ;

	my $path_file = "$path/" . Utils::get_date_uuid() ;
	$new_file->move_to($path_file);

    set_file_content($path_file . '.name', $new_file->filename) ;
    set_file_content($path_file . '.desc', $file_description) if $file_description ;
};

sub get_path{
	my($company_id,$id) = @_ ;
	return( "db/clients/$company_id/$id" ) ;
};

sub file_list4id{
	my ($company_id,$id) = @_ ;
	my $path = Utils::get_root_path(get_path($company_id,$id));
	if( ! -d $path ){
        system "mkdir -p '$path/'" ;
        return ;
    }
    
    my $dir;
    opendir($dir, $path);
	my $result = {};
    while (my $file = readdir($dir)) {
        next if ($file =~ m/^\./) || ($file =~ /[description|name]$/);
		$result->{ $file } = {};
        $result->{ $file }{name} = get_file_content("$path/$file" . '.name') ;
        $result->{ $file }{desc} = get_file_content("$path/$file" . '.desc') ;
    }
    closedir($dir);
	return($result);
};

sub set_file_content{
    my($file_path,$content) = @_ ;
	return(undef) if !$file_path || !$content ;
    my $fh;
    if( open($fh, "> :encoding(UTF-8)", $file_path) ){
        warn  "Cannot write to $file_path: $!" if ! (print $fh $content) ;
        warn "Cannot close $file_path: $!" if !close($fh) ;
    } else { warn "Cannot open $file_path: $!" } ;
};

sub get_file_content{
	my $file_path = shift;
	return(undef) if !$file_path ;
	my($fh,$content) = (undef,undef);
	if( -e $file_path ){
		if( open(my $fh, "< :encoding(UTF-8)", $file_path) ){
		    $content = do { local $/; <$fh> }; 
            warn "Cannot close $file_path: $!" if !close($fh) ;
        } else { warn "Cannot open $file_path: $!" } ;
		return($content)
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
