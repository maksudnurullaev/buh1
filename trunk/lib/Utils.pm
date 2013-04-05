package Utils; {

=encoding utf8

=head1 NAME

    Different utilites 

=cut

use 5.012000;
use strict;
use warnings;
use utf8;
use Crypt::SaltedHash;
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

sub salted_password{
    my $password = trim(shift); # password - generates salted password
    my $salt     = trim(shift); # salt     - just validate password and salt
    if(defined($password)){
        if(defined($salt)){
            return(scalar(Crypt::SaltedHash->validate($salt, $password)));
        }
        my $csh = Crypt::SaltedHash->new(algorithm => 'SHA-512');
        $csh->add($password);
        return($csh->generate);
    }
    return(undef);
};

sub get_admin_password_file_path{
    return(get_root_path('config','admin.login'));
};

sub set_admin_password{
    my $password = shift;
    if(defined($password) && $password){
        my ($file,$f) = (get_admin_password_file_path(), undef);
        my $salted_password = salted_password($password);
        open($f, ">", $file) || die("Can't open $file to write: $!");
        print $f $salted_password;
        close($f);
        return($salted_password);
    }
    return(undef);
};

sub get_admin_password{
    my $file = get_admin_password_file_path();
    if(! -e $file){ return(set_admin_password('admin')); }
    my ($f,$salted_password) = (undef,undef);
    open($f, "<", $file) || die("Can't open $file to read: $!");
    $salted_password = <$f>; # get just first line
    close($f);
    return($salted_password);
};

sub login{
    my($name,$password) = @_;
    # 1. Is administrator
    if( $name =~ /^admin$/i ){
        return(salted_password($password,get_admin_password));
    }
    warn "$name,$password";
    return(0);
};

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
