package Utils::Documents; {

=encoding utf8

=head1 NAME

    Documents utilites 

=cut

use 5.012000;
use strict;
use warnings;
use utf8;
use Data::Dumper;
use DbClient;
use Utils::Db;

sub attach{
    my ($self,$docid) = @_ ;
    return if !$docid ;
    my $db = Utils::Db::get_client_db($self);
    return if !$db;

    my $objects = $db->get_objects({id => [$docid], 
        field => ['document number', 'currency amount','details']});
    return(undef) if !$objects;
    my $document = $objects->{$docid};
    $self->session( docid => $docid );
    $self->session( document => $document );
};    

sub detach{
    my $self = shift;
    my $docid = $self->session->{docid};

    delete $self->session->{docid};
    delete $self->session->{document};
    return($docid);
};

sub get_document_number_next{
    my $self = shift;
    my $document_number_last = get_document_number_last($self);
    return($document_number_last + 1) if $document_number_last && $document_number_last =~ /^\d+$/ ;
    return("$document_number_last.1") if $document_number_last ;
    return('1');
};

sub get_document_number_last{
    my $self = shift;
    my $db = Utils::Db::get_client_db($self);
    my $sth = $db->get_from_sql(
        "SELECT value FROM objects WHERE name = 'document' AND field='document number' AND id=(SELECT MAX(id) FROM objects WHERE name='document');"
        );
    if( $sth && (my $result = $sth->fetch()) ){
        return $result->[0] if $result && $result->[0] ; 
    }
    return(undef);
};

sub document_number_exist{
    my $self = shift;
    my $document_number = shift;
    my $document_id     = shift;
    return(1) if !$document_number;

    my $db = Utils::Db::get_client_db($self);
    my $sql_string = " SELECT value FROM objects WHERE name = 'document' AND field='document number' AND value=? ";
    my $sth;
    if( $document_id ){
        $sql_string .= " AND id!=? ";
        $sth = $db->get_from_sql($sql_string,$document_number,$document_id);
    }else{
        $sth = $db->get_from_sql($sql_string,$document_number);
    }
    if( $sth && (my $result = $sth->fetch()) ){
        return $result->[0] if $result && $result->[0] ; 
    }
    return(undef);
};

sub get_tbalance_data{
    my ($self,$date1,$date2) = @_;
    my $result_where;
    if( $date2 ){
       $result_where = " value <= '$date2' "; 
    } else {
        return(undef);
    }
    my $sql_string = "SELECT * FROM objects WHERE id IN (SELECT DISTINCT id FROM objects WHERE name = 'document' AND field = 'date' AND $result_where );";
    my $db = Utils::Db::get_client_db($self);
    my $sth = $db->get_from_sql($sql_string);
    my $data = $db->format_statement2hash_objects($sth);
    return($data);
};

# END OF PACKAGE
};

1

__END__

=head1 AUTHOR

 M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
