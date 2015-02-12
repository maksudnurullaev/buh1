package Utils::Excel; {

=encoding utf8

=head1 NAME

    Excel utilites 

=cut

use 5.012000;
use strict;
use warnings;
use utf8;
use Utils;
use Spreadsheet::WriteExcel;
use Encode;

sub get_file_name_path{
    my $uuid = Utils::get_uuid();
    my $file_name = "export_current_$uuid.xls" ;
    my $file_path = "/tmp/$file_name" ;
    return(($file_name,$file_path));
};

sub utf_string{
    my $str = shift ;
    return(undef) if !$str;
    return(encode('UTF-8',$str));
};

sub warehouse_export_current{
    my ($self,$objects,$headers) = @_ ;
    return(undef) if !$objects || !$headers ;
    return(undef) if !scalar(keys(%{$headers})) || !scalar(keys(%{$objects}));

    my $uuid = Utils::get_uuid();
    my $file_name = "export_current_$uuid.xls" ;
    my $file_path = "/tmp/$file_name" ;

    # Create a new workbook 
    my $workbook  = Spreadsheet::WriteExcel->new($file_path);
    # Add worksheet
    my $worksheet = $workbook->add_worksheet($self->ml('Warehouse') . ' - Buh1.Uz');

    my $ord_headers = {};
    my $ord_int = 1 ;
    for my $name ( sort { Utils::utf_compare($self,$a,$b) } keys %{ $headers } ) {
        $ord_headers->{$ord_int++} = $name ;   
    }
    my ($ord_row,$ord_col) = (0,0);
    for my $idx (sort {$a <=> $b} keys %{$ord_headers}){
        $worksheet->write($ord_row,++$ord_col,$ord_headers->{$idx});
    }
    for my $pid (reverse sort keys %{$objects}){
        $ord_col = 0;
        $worksheet->write(++$ord_row,$ord_col++,$objects->{$pid}->{description});
        for my $idx (sort {$a <=> $b} keys %{$ord_headers}){
            my $name = $ord_headers->{$idx} ;   
            if( exists $objects->{$pid}->{tags}->{$name} ){
            $worksheet->write($ord_row,$ord_col++,$objects->{$pid}->{tags}->{$name});
            } else { $ord_col++; }
        }    
    }
    # final
    $workbook->close();
    return(($file_path,$file_name)) ;
}

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

 M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
