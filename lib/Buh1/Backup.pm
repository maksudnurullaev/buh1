package Buh1::Backup; {

=encoding utf8

=head1 NAME

    Accounts controller

=cut

use Mojo::Base 'Mojolicious::Controller';
use Utils::Files ;
use Utils ;
use Data::Dumper ;

sub auth{
    my $self = shift;
    if( !$self->is_user() ){ 
        $self->redirect_to('/user/login'); 
        return ; 
    }
    return(1);
};

sub list{
    my $self = shift;
    return if !auth($self) ;

    my $action = $self->param('payload');

	if( $self->req->method  eq 'POST' && $action eq 'add' ){
        make_new_archive $self ;
        $self->stash( success => 1 );
    }
    # finish
    make_list $self ;
};

sub make_list{
    my $self = shift ;

    my $root_path = Utils::get_root_path ;
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
    }
    $self->stash( archives => $archives );
};

sub make_new_archive{
    my ($self) = @_ ;

    my $root_path = Utils::get_root_path ;
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

sub get_client_archives_path{
	my $self = shift ;
    return if !auth($self) ;

    my $company_id = $self->session('company id') ;
    return( "db/archives/$company_id" ) ;
};

sub get_client_files_path{
	my $self = shift ;
    return if !auth($self) ;

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
