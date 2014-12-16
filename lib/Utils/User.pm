package Utils::User; {

=encoding utf8

=head1 NAME

    Different utilites 

=cut

use 5.012000;
use strict;
use warnings;
use utf8;
use Data::Dumper;
use ML;
use Utils::Languages;

sub current{
    my $self = shift;
    if( $self && $self->session ){
        return($self->session->{'user email'} );
    }
    return;
};

sub id{
    my $self = shift;
    if( $self ){
        return($self->session->{'user id'} );
    }
    return;
};

sub who_global{
    my $self = shift;
    my $email = current($self);
    # 1. Return undef if not registered yet
    return('g_guest') if !$email ;
    # 2. Is global admin
    return('g_admin') if( $email =~ /^admin$/i  );
    # 3. Check for other extension
    my $db = Db->new($self);
    my $user = $db->get_user($email);
    my $result = undef;
    $result = lc($user->{extended_right}) if $user
            && exists($user->{extended_right})
            && $user->{extended_right} ;
    return('g_' . who_normalize($result));
};

#GLOBAL
#                  guest user editor admin
#  Guest           1     0    0      0
#  Registered user 0     1    0      0
#  Editor          0     1    1      0
#  Admin           0     1    1      1
sub who_is_global{
    my ($self,$level) = @_ ;
    return(undef) if !$self || !$level;
    if( lc($level) eq 'admin' ){
        return(1) if who_global($self) =~ /g_admin/i ;
    } elsif( lc($level) eq 'editor' ){
        return(1) if who_global($self) =~ /g_admin|g_editor/i ;
    } elsif( lc($level) eq 'user' ){
        return(1) if who_global($self) =~ /g_admin|g_editor|g_registered/i ;
    } elsif( lc($level) eq 'guest' ){
        return(1) if who_global($self) eq 'g_guest' ;
    }
    return(0);
};

sub who_local{
    my $self = shift;
    my $email = current($self);
    # 1. Return 0 if not registered yet
    return('l_guest') if !$email ;
    # 2. Get actual right level
    my $result = undef;
    $result = lc($self->session->{'company access'})  
          if $self->session->{'company access'} ;
    return('l_' . who_normalize($result));
};

#LOCAL
#       reader writer admin  
#Reader 1      0      0
#Writer 1      1      0
#Admin  1      1      1
sub who_is_local{
    my ($self,$level) = @_ ;
    return(undef) if !$self || !$level;
    if( lc($level) eq 'admin' ){
        return(1) if who_local($self) =~ /l_admin/i ;
    } elsif( lc($level) eq 'writer' ){
        return(1) if who_local($self) =~ /l_admin|l_write/i ;
    } elsif( lc($level) eq 'reader' ){
        return(1) if who_local($self) =~ /l_admin|l_write|l_read/i ;
    }
    return(0);
};

sub who_normalize{
    my $result = shift;
    return('guest') if !$result;
    $result = lc $result;
    $result =~ s/\s/_/g;
    $result = 'registered' if $result eq 'no_rights'; # small hack ;-)
    return($result);
};

sub is_admin{
    my $self = shift;
    my $email = current($self);
    if( $email && $email =~ /^admin$/i ){
        return(1);
    }
    return(0);
};

sub is_editor{
    my $self = shift;
    my $email = current($self);
    # is admin
    return(1) if is_admin($self);
    # is editor
    if( $email ){
        my $db = Db->new($self);
        my $user = $db->get_user($email);
        return(1) if $user 
             && exists($user->{extended_right})
             && $user->{extended_right}
             && $user->{extended_right} =~ /editor/i ;
    }
    # not role
    return(0);
};

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
