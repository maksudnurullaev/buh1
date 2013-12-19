package Auth; {

=encoding utf8

=head1 NAME

    Authorization utilites 

=cut

use 5.012000;
use strict;
use warnings;
use utf8;
use Crypt::SaltedHash;
use Utils;
use Db;
use Data::Dumper;


sub salted_password{
    my $password = Utils::trim(shift); # password - generates salted password
    my $salt     = Utils::trim(shift); # salt     - just validate password and salt
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
    return(Utils::get_root_path('config','admin.login'));
};

sub set_admin_password{
    my $password = shift;
    if(defined($password) && $password){
        my ($file,$f) = (get_admin_password_file_path(), undef);
        my $salt = salted_password($password);
        open($f, ">", $file) || die("Can't open $file to write: $!");
        print $f $salt;
        close($f);
        return($salt);
    }
    return(undef);
};

sub get_admin_password{
    my $file = get_admin_password_file_path();
    if(! -e $file){ return(set_admin_password('admin')); }
    my ($f,$salt) = (undef,undef);
    open($f, "<", $file) || die("Can't open $file to read: $!");
    $salt = <$f>; # get just first line
    close($f);
    return($salt);
};

sub login{
    my($email,$password) = @_;
    $email = lc $email; # email string should be case insensative!!!
    # 1. Is administrator
    if( $email =~ /^admin$/i ){
        return(1) if salted_password($password,get_admin_password);
        warn "Admin's password invalid!";
        return(0);
    }
    # 2. Is email exists
    my $db = Db->new();
    my $user = $db->get_user($email);
    return(0) if !$user ;
    my $salt = $user->{password};
    return($user) if salted_password($password,$salt);
    warn "User with mail '$email' exists but password is invalid!";
    return(0);
};

sub set_password{
    my ($email, $password) = @_;
    # 1. Is administrator
    if( $email =~ /^admin$/i ){
        return(set_admin_password($password));
    }
    my $db = Db->new();
    my $user = $db->get_user($email);
    return(0) if !$user || 
            !exists($user->{id});
    my $id  = $user->{id}; 
    my $dbh = $db->get_db_connection() || return;
    my $sth = $dbh->prepare(
            "UPDATE objects SET value=? WHERE name='user' AND id=? AND field='password' ;");
    return(0) if !$sth->execute(salted_password($password),$id);
    return(1) ;
};

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
