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

	my $path      = Utils::get_root_path(get_path($self,$id));
	system "mkdir -p '$path/'" if ! -d $path ;
    # save file
	my $path_file = "$path/" . Utils::get_date_uuid() ;
	$new_file->move_to($path_file);
	# save file name
    set_file_content($path_file . '.name', $new_file->filename) ;
    my $file_description = $self->param('file.desc');
	# save file description
    set_file_content($path_file . '.desc', $file_description) if $file_description ;
    return(1)
};

sub del_file{
    my $self = shift;
    my $id = $self->param('payload');
    my $fileid = $self->param('fileid');

	my $path       = Utils::get_root_path(get_path($self,$id));
	my $path_file  = "$path/$fileid" ;
	
	unlink $path_file ;
    unlink ($path_file . '.name') ;
    unlink ($path_file . '.desc') ;
};

sub update_file{
    my $self = shift;
    my $id = $self->param('payload');
    my $fileid = $self->param('fileid');

    return(0) if $self->req->is_limit_exceeded ;

	my $new_file = $self->param('new_file');
	return(0) if( !$new_file || !$new_file->size ) ;

	my $path      = Utils::get_root_path(get_path($self,$id));
	my $path_file = "$path/$fileid" ;
	$new_file->move_to($path_file) ;
    set_file_content($path_file . '.name', $new_file->filename) ;
    return(1)
};

sub update_desc{
    my $self = shift;
    my $id = $self->param('payload');
    my $fileid = $self->param('fileid');
    my $file_description = $self->param('file.desc');

	my $path      = Utils::get_root_path(get_path($self,$id));
	my $path_file = "$path/$fileid" . '.desc' ;
    set_file_content($path_file, $file_description) ;
};

sub get_path{
	my($self,$id) = @_ ;
    my $controller = $self->param('prefix') || $self->stash('controller');
	if( $controller =~ /templates/i ){ # admin actions
		return( "db/main/$id") ;
	} 
    my $company_id = $self->session('company id') ;
    return( "db/clients/$company_id/$id" ) ;
};

sub deploy{
    my($self,$id,$fileid) = @_ ;
    my $path = Utils::get_root_path(get_path($self,$id));
    my $file_path = "$path/$fileid" ;
    return if ! -e $file_path ;
    $self->stash( 'file_name' => get_file_content($file_path . '.name') )
        if -e ($file_path . '.name');
    $self->stash( 'file_desc' => get_file_content($file_path . '.desc') )
        if -e ($file_path . '.desc');
};

sub files_count{
    my($self,$id) = @_ ;
    my $path = Utils::get_root_path(get_path($self,$id));
    return(0) if ! -d $path;
    my @files = <"$path/*.name">;
    return(scalar(@files));
};

sub file_list4id{
	my ($self,$id) = @_ ;
	my $path = Utils::get_root_path(get_path($self,$id));
	if( ! -d $path ){
        system "mkdir -p '$path/'" ;
        return ;
    }
    
    my $dir;
    opendir($dir, $path);
	my $result = {};
    while (my $fileid = readdir($dir)) {
        next if ($fileid =~ m/^\./) || ($fileid =~ /[desc|name]$/);
		$result->{ $fileid } = {};
        $result->{ $fileid }{name} = get_file_content("$path/$fileid" . '.name') ;
        $result->{ $fileid }{desc} = get_file_content("$path/$fileid" . '.desc') ;
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

sub is_file_writer{
    my $self = shift;
    my $controller = $self->stash('prefix') || $self->stash('controller');
    if( $controller ){
        if( $controller =~ /^templates/i ){
            return Utils::is_admin($self);
        } else {
            my $user_role = Utils::user_role2company($self);
            return ( $user_role && $user_role =~ /[admin|write]/i ) ;
        }
    }
    return(0);
};

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

 M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
