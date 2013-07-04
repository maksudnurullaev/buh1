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

sub get_objects{
    my $parameters = shift;
    my $self          = $parameters->{self};
    my $name          = $parameters->{name};
    my $names         = $parameters->{names};
    my $filter        = $parameters->{filter};
    my $filter_field  = $parameters->{filter_field};
    my $result_fields = $parameters->{result_fields};
    my $filter_where;
    my $result;
    my $db = Db->new();
    if( $filter ) {
        $self->stash(filter => $filter) if $filter;
        $filter_where = " field='$filter_field' AND value LIKE '%$filter%' ESCAPE '\\' ";
        $result = $db->get_counts({name=>[$name], add_where=>$filter_where});
    } else {
        $result = $db->get_counts({name=>[$name],field=>[$filter_field]}); 
    }
    return if !$result; # count is 0
    #paginator
    my $paginator = Utils::get_paginator($self,$names,$result);
    $self->stash(paginator => $paginator);        
    my ($limit,$offset) = (" LIMIT $paginator->[2] ",
            $paginator->[2] * ($paginator->[0] - 1));
    $limit .= " OFFSET $offset " if $offset ; 
    # find real records if exist
    if( $filter ) {
        $result = $db->get_objects({
            name      => [$name], 
            add_where => $filter_where,
            limit     => $limit});
    } else {
        $result = $db->get_objects({
            name  => [$name],
            field => [$filter_field],
            limit => $limit}); 
    }
    # final
    map { $result->{$_} = 
        $db->get_objects({
            name  => [$name],
            field => $result_fields})->{$_} }
        keys %{$result};
    return($result);
};


# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut

