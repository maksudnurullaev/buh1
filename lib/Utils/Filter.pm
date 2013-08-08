package Utils::Filter; {

=encoding utf8

=head1 NAME

    Different utilites 

=cut

use 5.012000;
use strict;
use warnings;
use utf8;

sub pagesize{
    my ($self,$pagesize4) = @_;
    my $pagesize = $self->param('payload');
    if ( $pagesize && $pagesize =~/^\d+$/ ){
        $self->session->{"$pagesize4/filter/pagesize"} = $pagesize;
    }
};

sub page{
    my ($self,$page4) = @_;
    my $page = $self->param('payload');
    if ( $page && $page =~/^\d+$/ ){
        $self->session->{"$page4/filter/page"} = $page;
    }
};

sub nofilter{
    my ($self,$nofilter4) = @_;
    if( $nofilter4 ){
        my $path   = Utils::trim $self->param('path');
        delete $self->session->{$nofilter4};
    }
};

sub filter{
    my ($self,$filter4) = @_;
    my $filter_path = "$filter4/filter";
    my $filter_value = Utils::trim $self->param('filter');
    if( $filter_value ){
        $self->session->{$filter_path} = $filter_value;
    }
};

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut

