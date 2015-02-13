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
use Data::Dumper ;

sub get_file_name_path{
    my $uuid = Utils::get_uuid();
    my $file_name = "export_current_$uuid.xls" ;
    my $file_path = "/tmp/$file_name" ;
    return(($file_name,$file_path));
};

sub warehouse_prepare{
    my ($self,$scope) = @_ ;
    my $objects = $scope eq 'current' ? Utils::Warehouse::current_list_objects($self)
        : Utils::Warehouse::get_all_objects($self);
    # 1. Get all tags
    for my $pid (keys %{$objects}){
        my $counting_field_id;
        $counting_field_id = $objects->{$pid}{counting_field} if exists $objects->{$pid}{counting_field};
        my $tags = 
            Utils::Db::cdb_get_links($self, 
                $pid, 
                Utils::Warehouse::tag_object_name(), 
                ['name','value'] );
        for my $tagid (keys %{$tags}){
            $objects->{$pid}{tags} = {} if !exists $objects->{$pid}{tags} ;
            if( $counting_field_id 
                    && $counting_field_id eq $tagid
                    && $tags->{$tagid}{value}){
                if( exists $objects->{$pid}{counting_direction} &&
                    $objects->{$pid}{counting_direction} eq '-'){
                    $objects->{$pid}{tags}{$tags->{$tagid}{name}} = $tags->{$tagid}{value} * (-1) ;
                } else {
                    $objects->{$pid}{tags}{$tags->{$tagid}{name}} = $tags->{$tagid}{value} ;
                }
            } else {
                $objects->{$pid}{tags}{$tags->{$tagid}{name}} = $tags->{$tagid}{value} ;
            }
       }    
    }
    # 2. Get all header tags
    my $headers = {};
    for my $pid (keys %{$objects}){
        my $tags  = $objects->{$pid}{tags};
        next if !$tags;
        for my $name (keys %{$tags}){
            if( !exists($headers->{$name}) ) {
                $headers->{$name} = 1 ;
            } else {
                $headers->{$name}++ ;
            }
        }
    }
    return(($objects,$headers));
};

sub warehouse_export{
    my ($self,$scope,$type) = @_ ;
    my ($objects,$headers) = warehouse_prepare($self,$scope) ;
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
    return(($file_path,$file_name,$objects,$headers)) if $type eq '.xls' ;
    my $command = '7z a ';
    if( $type eq '.zip' ){
        $command .= " -tzip $file_path" . ".zip  $file_path ";
        system($command);
        return((($file_path . '.zip'),($file_name . '.zip'),$objects,$headers));
    } else {
        $command .= " $file_path" . ".7z  $file_path ";
        system($command);
        return((($file_path . '.7z'),($file_name . '.7z'),$objects,$headers));
    }
};

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

 M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
