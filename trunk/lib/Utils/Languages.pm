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

sub get{
    ['eng', 'rus', 'uzb'];
};

sub current{
    my $self = shift;
    if( defined($self)
            && defined($self->session)
            && exists($self->session->{'lang'}) ){
        return ( $self->session->{'lang'} || $DEFAULT_LANG ) ;
    }
    return($DEFAULT_LANG);
};

sub bar{
    my $self = shift;
    my $format = shift || $DEFAULT_FORMAT;
    my $result;
    my $current_lang = current($self);
    foreach(@{get()}){
        if($_ eq $current_lang){
            $result .= ($result ? " $_" : $_ );
        } else {
            $result .= ($result ? " " : "" ) . sprintf($format, $_, $_);
        }
    }
    return (Mojo::ByteStream->new($result));
};

sub generate_name{
    my ($self,$hashref) = @_;
    my ($langs,$lang)   = (get(),current($self));
    return(undef) if !$hashref || !$langs || !$lang ;
    for my $key (keys %{$hashref}){
        if( ref $hashref->{$key} eq 'HASH' ){
            generate_name($self,$hashref->{$key});
        }
    }
    my $found = 0;
    if ( exists($hashref->{$lang}) && 
         $hashref->{$lang} ){
        $hashref->{name} = $hashref->{$lang}
    }else{
        my @result = ();
        my @names = ("-$lang");
        for my $name (@{$langs}){
            if($name ne $lang && exists($hashref->{$name})){
                push @names, "+$name"; 
                push @result, $hashref->{$name};
            }
        }

        $hashref->{name} = 
            '[' . join('/',@names) . '] ' . join('/',@result)
            if @result; 
    }
};

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
