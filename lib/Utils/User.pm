package Utils::User;
{

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

    sub authorized2password {
        my $self = shift;
        if ( $self->who_is_global('guest') ) {
            $self->redirect_to('/user/login?warning=access');
            return (0);
        }
        return (1);
    }

    sub current {
        my $self = shift;
        if ( $self && $self->session ) {
            return ( $self->session->{'user email'} );
        }
        return (undef);
    }

    sub id {
        my $self = shift;
        if ($self) {
            return ( $self->session->{'user id'} );
        }
        return;
    }

    sub who_global {
        my $self  = shift;
        my $email = current($self);

        # 0. For guests
        return ('g_guest') if !$email;

        # 1. Is global admin
        return ('g_admin') if ( $email =~ /^admin$/i );

        # 2. Is user registered, not registered yet
            my $result = 'user';
            # 2.1 Is user has extended right
        my $db   = Db->new($self);
        my $user = $db->get_user($email);
        if ( exists( $user->{extended_right} ) ) {
            $result = $user->{extended_right} if $user->{extended_right};
        }
        return ( 'g_' . who_normalize($result) );
    }

    #GLOBAL
    #                    guest user editor admin
    #  Guest             1     0    0      0
    #  (registered) User 0     1    0      0
    #  Editor            0     1    1      0
    #  Admin             0     1    1      1
    sub who_is_global {
        my ( $self, $level ) = ( shift, lc(shift) );
        return (undef) if !$self || !$level;
        my $who_global = lc( who_global($self) );
        if ( $level eq 'admin' ) {
            return (1) if $who_global =~ /g_admin/i;
        }
        elsif ( $level eq 'editor' || lc($level) eq 'writer' ) {
            return (1) if $who_global =~ /g_admin|g_editor/i;
        }
        elsif ( $level eq 'user' ) {
            return (1)
              if $who_global =~ /g_admin|g_editor|g_user/i;
        }
        elsif ( $level eq 'guest' ) {
            return (1) if $who_global =~ /g_guest/i;
        }
        return (0);
    }

    sub who_local {
        my $self  = shift;
        my $email = current($self);

        # 1. Return 0 if not registered yet
        return ('l_guest') if !$email;

        # 2. Get actual right level
        my $result = undef;
        $result = lc( $self->session->{'company access'} )
          if $self->session->{'company access'};
        return ( 'l_' . who_normalize($result) );
    }

    # Local OR Company rights 
    #          reader writer admin
    #Reader    1      0      0
    #Writer    1      1      0
    #Admin     1      1      1
    sub who_is_local {
        my ( $self, $level ) = @_;
        return (undef) if !$self || !$level;
        my $who_local = who_local($self);
        if ( lc($level) eq 'admin' ) {
            return ($who_local) if $who_local =~ /l_admin/i;
        }
        elsif ( lc($level) eq 'writer' || lc($level) eq 'editor' ) {
            return ($who_local) if $who_local =~ /l_admin|l_write/i;
        }
        elsif ( lc($level) eq 'reader' ) {
            return ($who_local) if $who_local =~ /l_admin|l_write|l_read/i;
        }
        return (undef);
    }

    sub who_is {
        my ( $self, $part, $level ) = @_;
        my $result = 0;
        if ( $self && $part && $level ) {
            $result = who_is_global( $self, $level ) if lc($part) eq 'global';
            $result = who_is_local( $self, $level )  if lc($part) eq 'local';
        }
        $self->redirect_to('/user/login?warning=access')
          if !$result;    # default action
        return ($result);
    }

    sub who_normalize {
        my $result = shift;
        return ('guest') if !$result;
        $result = lc $result;
        $result =~ s/\s/_/g;
        $result = 'user' if $result eq 'no_rights';    # small hack ;-)
        return ($result);
    }

    # END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
