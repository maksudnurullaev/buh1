package Utils; {

=encoding utf8

=head1 NAME

    Different utilites 

=cut

use 5.012000;
use strict;
use warnings;
use utf8;
use Cwd;
use Time::Piece;
use Data::UUID;
use File::Spec;
use File::Path qw(make_path);

sub trim{
    my $string = $_[0];
    if(defined($string) && $string){
        $string =~ s/^\s+|\s+$//g;
        return($string);
    }
    return(undef);
};

sub get_uuid{
    my $ug = new Data::UUID;
    my $uuid = $ug->create;
    my @result = split('-',$ug->to_string($uuid));
    return($result[0]);
};

sub get_date_uuid{
    my $result= Time::Piece->new->strftime('%Y.%m.%d %T ');
    return($result . get_uuid());
};

sub get_root_path{
    my $path = shift;
    if($path){
        my $file = shift;
        if($file){
            return(File::Spec->catfile((cwd(), $path), $file));
        } else {
            return(File::Spec->catdir(cwd(), $path));
        }
    } else {
        return(cwd());
    }
};


# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
