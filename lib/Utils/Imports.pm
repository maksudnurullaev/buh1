package Utils::Imports;

=encoding utf8

=head1 NAME

    Utilites 

=cut

use 5.012000;
use strict;
use warnings;
use utf8;

use Data::Dumper;

use Mojo::DOM;

sub get_dom_deep_text {

    my $dom = shift;
    return if !$dom;

    my $content = $dom->content;
    $content =~ s/\<br\>/_BR_/ig;
    my $dom_new = Mojo::DOM->new($content);
    my $collections =
      $dom_new->descendant_nodes->grep( sub { $_->type eq 'text' } );
    return $collections->size ? $collections->first->content : '';
}

# END OF PACKAGE

1;

__END__

=head1 AUTHOR

 M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
