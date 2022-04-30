package Buh1::Backup; {

=encoding utf8

=head1 NAME

    Accounts controller

=cut

use Mojo::Base 'Mojolicious::Controller';
use Utils::Files ;
use Utils ;
use Data::Dumper ;

sub list{
    my $self = shift;
    return if !$self->who_is('local','reader');
    my $_action = $self->param('payload');

	if( $self->req->method  eq 'POST' && $_action eq 'add' ){
        make_new_archive $self ;
        $self->stash( success => 1 );
    }
    make_list $self ;
};

sub del{
    my $self = shift ;
    return if !$self->who_is('local','writer');
    my $file = $self->param('payload');
    my $archives_path = get_client_archives_path($self); 
    my @deletes = ("$archives_path/$file", "$archives_path/$file.desc") ;
    unlink @deletes ;
    $self->redirect_to('/backup/list');
};

sub update{
    my $self = shift ;
    return if !$self->who_is('local','writer');
    my $file = $self->param('payload');
    my $archives_path = get_client_archives_path($self); 
    my $archive_file = "$archives_path/$file" ;
	my $new_archive = $self->param('new_archive');
    $new_archive->move_to($archive_file) ;
    $self->redirect_to("/backup/edit/$file");
};

sub edit{
    my $self = shift ;
    return if !$self->who_is('local','writer');
    my $file = $self->param('payload');
    my $archives_path = get_client_archives_path($self); 
    my $archive_file = "$archives_path/$file" ;
    my $archive_file_desc = "$archives_path/$file.desc" ;
    if( ! -f $archive_file ){
        $self->redirect_to('/backup/list');
        return;
    }
    my $file_size = -s $archive_file ;
    $self->stash( archive_desc => Utils::Files::get_file_content($archive_file_desc) );  
    $self->stash( archive_size => $file_size );
};

sub download{
    my $self = shift ;
    return if !$self->who_is('local','writer');
    my $file = $self->param('payload');
    my $archives_path = get_client_archives_path($self); 
    my $archive_file = "$archives_path/$file" ;
    $self->stash( 'file.name' => $file );
    $self->render_file('filepath' => $archive_file, 'filename' => $file);
};

sub update_desc{
    my $self = shift ;
    return if !$self->who_is('local','writer');
    my $file = $self->param('payload');
    my $archives_path = get_client_archives_path($self); 
    my $archive_file_desc = "$archives_path/$file.desc" ;
    my $description = $self->param("archive_desc");
    Utils::Files::set_file_content($archive_file_desc,$description);
    $self->redirect_to("/backup/edit/$file");
};

sub make_list{
    my $self = shift ;
    my $root_path = $self->app->home->to_string();
    chdir $root_path ;
    my $archives_path = get_client_archives_path($self); 
    if( ! -d $archives_path ){
        system "mkdir -p '$archives_path/'" ;
        return;
    }
    my $archives = {};
    my $dir ;
    opendir($dir, $archives_path);
    while (my $fileid = readdir($dir)) {
        next if ($fileid =~ m/^\./) || ($fileid =~ /[desc|name]$/);
        $archives->{ $fileid } = {};
        my $desc_path = "$archives_path/$fileid.desc" ;
        $archives->{ $fileid }{desc} = Utils::Files::get_file_content($desc_path) ;
        $archives->{ $fileid }{size} = ( -s  "$archives_path/$fileid") ;
    }
    $self->stash( archives => $archives );
};

sub make_new_archive{
    my ($self) = @_ ;

    my $root_path = $self->app->home->to_string();
    chdir $root_path ;
    my $archives_path = get_client_archives_path($self);
    my $archive_name = Utils::get_date_uuid();
    my $archive_file = "$archives_path/$archive_name.tar.gz" ;
    system "mkdir -p '$archives_path'" if ! -d $archives_path ;

    my $client_path = get_client_files_path($self);
    my $company_id = $self->session('company id') ;
    
    system "tar czf '$archive_file' '$client_path' '$client_path.db'" ;
    if( my $file_description = $self->param('archive.desc') ){
        Utils::Files::set_file_content("$archive_file.desc",$file_description) ;
    }
    return(1)
};

sub restore{
    my $self = shift ;
    return if !$self->who_is('local','writer');
    my $file = $self->param('payload');
    my $archives_path = get_client_archives_path($self); 
    my $archive_file = "$archives_path/$file" ;
    system "tar xzf '$archive_file' " ;
    $self->redirect_to("/backup/edit/$file");
};

sub get_client_archives_path{
	my $self = shift ;
    my $company_id = $self->session('company id') ;
    return( "db/archives/$company_id" ) ;
};

sub get_client_files_path{
	my $self = shift ;
    my $company_id = $self->session('company id') ;
    return( "db/clients/$company_id" ) ;
};


# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
