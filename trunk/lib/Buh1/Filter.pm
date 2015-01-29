package Buh1::Filter; {

=encoding utf8

=head1 NAME

    For filterinf and paginating controller

=cut

use Mojo::Base 'Mojolicious::Controller';
use Utils::Filter ;
use Utils ;
use Encode qw( encode decode_utf8 );


sub pagesize{ Utils::Filter::pagesize(shift); };
sub page{ Utils::Filter::page(shift); };
sub nofilter{ Utils::Filter::nofilter(shift); };
sub filter{ Utils::Filter::filter(shift); };

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
