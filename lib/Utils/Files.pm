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

sub validate_file{
    my $self = shift;
    my $fileid = $self->param('fileid') ;
    if( $self->req->is_limit_exceeded 
        || !$self->param('file.field')
        || !$self->param('file.field')->size ){
        $self->redirect_to( $self->param('path') . '?error=1' . ($fileid?"&fileid=$fileid":'') );
        return(0);
    }
    return(1);
};

sub update_desc{
    my $self   = shift;
    my $fileid = $self->param('fileid');
    my $pid = $self->param('pid');
    my $file_description = $self->param('file.desc');

    my $path = get_path($self,$pid);
    system "mkdir -p '$path/'" if ! -d $path ;
    # save file
    my $path_file = "$path/$fileid" ;
    # save file description
    set_file_content($path_file . '.desc', $file_description) if $file_description ;
    $self->redirect_to( $self->param('path') . "?fileform=update&fileid=$fileid&success=1" );
    return(1)
};

sub add{
    my $self = shift;
    my $pid = $self->param('pid');

    return(0) if !validate_file($self) ;

    my $file = $self->param('file.field');
    my $path = get_path($self,$pid);
    system "mkdir -p '$path/'" if ! -d $path ;
    # save file
    my $path_file = "$path/" . Utils::get_date_uuid() ;
    $file->move_to($path_file);
    # save file name
    set_file_content($path_file . '.name', $file->filename) ;
    my $file_description = $self->param('file.desc');
    # save file description
    set_file_content($path_file . '.desc', $file_description) if $file_description ;
    $self->redirect_to( $self->param('path') . '?success=1' );
    return(1)
};

sub delete{
    my $self = shift;
    my $fileid = $self->param('fileid');
    my $pid = $self->param('pid');

    my $path       = get_path($self,$pid);
    my $path_file  = "$path/$fileid" ;
    
    unlink $path_file ;
    unlink ($path_file . '.name') ;
    unlink ($path_file . '.desc') ;
    $self->redirect_to( $self->param('path') . '?success=1' );
};

sub update_file{
    my $self = shift;
    my $pid = $self->param('pid');
    my $fileid = $self->param('fileid');
    my $path   = $self->param('path');
    return(0) if !validate_file($self) ;

    my $file = $self->param('file.field');
    my $path      = get_path($self,$pid);
    my $path_file = "$path/$fileid" ;
    $file->move_to($path_file) ;
    set_file_content($path_file . '.name', $file->filename) ;
    $self->redirect_to( $self->param('path') . "?success=1&fileid=$fileid" );
    return(1)
};

sub get_path{
    my($self,$id) = @_ ;
    my $controller = $self->param('prefix') || $self->stash('controller');
    if( $controller =~ /templates/i ){ # admin actions
        return( $self->app->home->rel_dir("db/main/$id") ) ;
    } 
    my $company_id = $self->session('company id') ;
    return( $self->app->home->rel_dir("db/clients/$company_id/$id") ) ;
};

sub deploy{
    my($self,$id,$fileid) = @_ ;
    my $path = get_path($self,$id);
    my $file_path = "$path/$fileid" ;
    return if ! -e $file_path ;
    $self->stash( 'file_name' => get_file_content($file_path . '.name') )
        if -e ($file_path . '.name');
    $self->stash( 'file_desc' => get_file_content($file_path . '.desc') )
        if -e ($file_path . '.desc');
};

sub files_count{
    my($self,$id) = @_ ;
    my $path = get_path($self,$id);
    return(0) if ! -d $path;
    my @files = <"$path/*.name">;
    return(scalar(@files));
};

sub file_list4id{
    my ($self,$id) = @_ ;
    my $path = get_path($self,$id);
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

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

 M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
