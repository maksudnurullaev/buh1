package Buh1::Guides; {

=encoding utf8

=head1 NAME

    Accounts controller

=cut

use Mojo::Base 'Mojolicious::Controller';
use Utils::Files ;
use Utils ;
use Encode qw( encode decode_utf8 );
use Data::Dumper ;

sub page{
    my $self = shift;
    my $guides_path = get_guides_path($self);
    my $guides = {};
    my $dir ;
    opendir($dir, $guides_path);
    while( my $file = readdir($dir) ) {
        next if ($file =~ m/^\./) || ($file =~ /desc$/);
        $guides->{ $file } = {};
        my $desc_path = "$guides_path/$file.desc" ;
        $guides->{ $file }{desc} = Utils::Files::get_file_content($desc_path) ;
        $guides->{ $file }{size} = ( -s  "$guides_path/$file") ;
    }

    $self->stash( guides_path => $guides_path );
};

# END OF PACKAGE

};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
