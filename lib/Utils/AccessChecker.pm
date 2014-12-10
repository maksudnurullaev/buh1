package Utils::AccessChecker; {

=encoding utf8


=head1 NAME

    Access checker

=head1 USAGE

   Will added soon...

=cut

use 5.012000;
use strict;
use warnings;
use utf8;
use Carp;
use Utils::User;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(ac_is_user ac_is_authorized);


sub ac_is_user{
    my $c = shift;
    if( !Utils::User::current($c) ){
        $c->redirect_to('/user/login');
        return(0);
    }
    return(1);
};

sub ac_is_authorized{
    my ($c,$access) = @_;
    return(0) if !ac_is_user($c) ;
    if( !defined($c->user_role2company) 
		|| $c->user_role2company !~ /$access/i ){
        $c->redirect_to('/user/login');
        return(0); 
    }
    return(1);
};



};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut

