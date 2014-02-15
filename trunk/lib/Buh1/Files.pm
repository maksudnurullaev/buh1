package Buh1::Files; {

=encoding utf8

=head1 NAME

    Accounts controller

=cut

use Mojo::Base 'Mojolicious::Controller';
use Utils::Files ;
use Utils ;
use Encode qw( encode decode_utf8 );
use Data::Dumper ;

sub download{
    my $self = shift;
    my $id         = $self->param('payload');
    my $fileid     = $self->param('fileid');
	my $path       = Utils::get_root_path(Utils::Files::get_path($self,$id));
    my $file_path  = "$path/$fileid" ;
    my $file_name  = Utils::Files::get_file_content("$path/$fileid" . '.name') ;

    $self->stash( 'file.name' => $file_name );
    $self->render_file('filepath' => $file_path, 'filename' => $file_name);
};

sub update_desc{
    my $self = shift;
    my $desc = $self->param('file.desc');
    my $redirect_to = $self->param('redirect_to');


};

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
