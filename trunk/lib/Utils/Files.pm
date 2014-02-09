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

sub add_new{
    my $self = shift;
    my $id = $self->param('payload');

    return(0) if $self->req->is_limit_exceeded ;

	my $new_file = $self->param('new_file');
	return(0) if( !$new_file || !$new_file->size ) ;

    my $company_id = $self->session('company id') ;
    my $file_description = $self->param('file.desc');

	my $path      = Utils::get_root_path(get_path($self,$company_id,$id));
	system "mkdir -p '$path/'" if ! -d $path ;

	my $path_file = "$path/" . Utils::get_date_uuid() ;
	$new_file->move_to($path_file);

    set_file_content($path_file . '.name', $new_file->filename) ;
    set_file_content($path_file . '.desc', $file_description) if $file_description ;
    return(1)
};

sub del_file{
    my $self = shift;
    my $id = $self->param('payload');
    my $file = $self->param('file');

    my $company_id = $self->session('company id') ;
	my $path       = Utils::get_root_path(get_path($self,$company_id,$id));
	my $path_file  = "$path/$file" ;
	
	unlink $path_file ;
    unlink ($path_file . '.name') ;
    unlink ($path_file . '.desc') ;
};

sub update_file{
    my $self = shift;
    my $id = $self->param('payload');
    my $file = $self->param('file');

    return(0) if $self->req->is_limit_exceeded ;

	my $new_file = $self->param('new_file');
	return(0) if( !$new_file || !$new_file->size ) ;

    my $company_id = $self->session('company id') ;
	my $path      = Utils::get_root_path(get_path($self,$company_id,$id));

	my $path_file = "$path/$file" ;
	$new_file->move_to($path_file) ;
    set_file_content($path_file . '.name', $new_file->filename) ;
    return(1)
};

sub update_desc{
    my $self = shift;
    my $id = $self->param('payload');
    my $file = $self->param('file');
    my $file_description = $self->param('file.desc');
    my $redirect_to = $self->param('redirect_to');
    my $company_id = $self->session('company id') ;

	my $path      = Utils::get_root_path(get_path($self,$company_id,$id));
	my $path_file = "$path/$file" . '.desc' ;
    set_file_content($path_file, $file_description) ;
};

sub get_path{
	my($self,$company_id,$id) = @_ ;
	return( "db/main/$id") if( -d "db/main/$id" ) ;
    return( "db/clients/$company_id/$id" ) ;
};

sub deploy{
    my($self,$id,$file) = @_ ;
    my $company_id = $self->session('company id');
    my $path = Utils::get_root_path(get_path($self,$company_id,$id));
    my $file_path = "$path/$file" ;
    return if ! -e $file_path ;
    $self->stash( 'file_name' => get_file_content($file_path . '.name') )
        if -e ($file_path . '.name');
    $self->stash( 'file_desc' => get_file_content($file_path . '.desc') )
        if -e ($file_path . '.desc');
};

sub files_count{
    my($self,$id) = @_ ;
    my $company_id = $self->session('company id');
    my $path = Utils::get_root_path(get_path($self,$company_id,$id));
    return(0) if ! -d $path;
    my @files = <"$path/*.name">;
    return(scalar(@files));
};
sub file_list4id{
	my ($self,$company_id,$id) = @_ ;
	my $path = Utils::get_root_path(get_path($self,$company_id,$id));
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
