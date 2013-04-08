package Utils::Languages; {

=encoding utf8

=head1 NAME

    Different utilites 

=cut

use 5.012000;
use strict;
use warnings;
use utf8;

our $DEFAULT_FORMAT = '<a href="/initial/lang/%s">%s</a>'; 
our $DEFAULT_LANG   = 'rus';
our @DEFAULT_LANGS  = ('eng', 'rus', 'uzb');

sub current{
    my $self = shift;
    my $current_lang = $self->session->{'lang'} || $DEFAULT_LANG;
    return($current_lang);
};

sub bar{
    my $self = shift;
    my $format = shift || $DEFAULT_FORMAT;
    my $result;
    my $current_lang = current($self);
    foreach(@DEFAULT_LANGS){
        if($_ eq $current_lang){
            $result .= ($result ? " $_" : $_ );
        } else {
            $result .= ($result ? " " : "" ) . sprintf($format, $_, $_);
        }
    }
    return (Mojo::ByteStream->new($result));
};

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
