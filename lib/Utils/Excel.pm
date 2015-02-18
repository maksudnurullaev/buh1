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

sub warehouse_prepare{
    my ($self,$scope) = @_ ;
    my $objects = $scope eq 'current' ? Utils::Warehouse::current_list_objects($self)
        : Utils::Warehouse::get_all_objects($self);
    return(get_objects_headers($self,$objects));
};

sub get_objects_headers{
    my ($self,$objects) = @_ ;
    return if !$objects ;
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

sub get_new_file_path_name{
    my $uuid = Utils::get_uuid();
    my $file_name = "buh1_export_$uuid.xls" ;
    my $file_path = "/tmp/$file_name" ;
    return(($file_path,$file_name));
};

sub warehouse_export{
    my ($self,$scope,$type) = @_ ;
    my ($objects,$headers) = warehouse_prepare($self,$scope) ;
    return(undef) if !$objects || !$headers ;
    return(undef) if !scalar(keys(%{$headers})) || !scalar(keys(%{$objects}));

    my ($file_path,$file_name) = get_new_file_path_name();

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
    ($file_path,$file_name) = make_zipped_file(($file_path,$file_name,$type));
    return(($file_path,$file_name,$objects,$headers));
};

sub make_zipped_file{
    my ($file_path,$file_name,$type) = @_ ;
    my $command = '7z a ';
    if( $type eq '.zip' ){
        $command .= " -tzip $file_path" . ".zip  $file_path ";
        system($command);
        return((($file_path . '.zip'),($file_name . '.zip')));
    } else {
        $command .= " $file_path" . ".7z  $file_path ";
        system($command);
        return((($file_path . '.7z'),($file_name . '.7z')));
    }
};

sub merge_parent_and_childs{
    my ($parent,$childs) = @_ ;
    my $fields = ['description','counting_field','counting_parent','counting_direction'] ;
    my $pid = $parent->{id};
    my $result = {} ;
    $result->{$pid} = {} ;
    for my $field (@{$fields}){
        $result->{$pid}{$field} = $parent->{$field} if exists $parent->{$field} ;
    }
    for my $cid (keys %{$childs}){
        $result->{$cid} = {};
        for my $field (@{$fields}){
            $result->{$cid}{$field} = $childs->{$cid}{$field} if exists $childs->{$cid}{$field} ;
        }
    }
    return($result);
};

sub warehouse_export_remains{
    my ($self,$type,$pids) = @_ ;
    my ($file_path,$file_name) = get_new_file_path_name();
    # Create a new workbook 
    my $workbook  = Spreadsheet::WriteExcel->new($file_path);
    my $bold = $workbook->add_format(bold => 1);
    # Add worksheet
    my $worksheet = $workbook->add_worksheet($self->ml('Warehouse') . ' - Buh1.Uz');
    $worksheet->set_column('A:A', 30);
    my $ord_row = 0;
    for my $pid (@{$pids}){
        $ord_row = make_remains_outline($self,$pid,$worksheet,$ord_row,$bold) if $pid;
    }
    # final
    $workbook->close();
    return(($file_path,$file_name)) if $type eq '.xls' ;
    ($file_path,$file_name) = make_zipped_file(($file_path,$file_name,$type));
    return(($file_path,$file_name));
};

sub make_remains_outline{
    my ($self,$pid,$worksheet,$ord_row,$bold) = @_ ;
    my ($parent,$childs,$caclulated_counting) 
        = Utils::Warehouse::calculated_counting($self,$pid);
    my ($objects,$headers) = (merge_parent_and_childs($parent,$childs), undef);
    ($objects,$headers) = get_objects_headers($self,$objects) ;
    return($ord_row) if !$objects || !$headers ;
    return($ord_row) if !scalar(keys(%{$headers})) || !scalar(keys(%{$objects}));
    my $ord_headers = {};
    my $ord_int = 1 ;
    for my $name ( sort { Utils::utf_compare($self,$a,$b) } keys %{ $headers } ) {
        $ord_headers->{$ord_int++} = $name ;   
    }
    my $ord_col = 0;
    # total
    my $total_name = $parent->{description};
    $worksheet->write($ord_row,   0, $total_name, $bold);
    $worksheet->write($ord_row++, 1, $caclulated_counting, $bold);
    $worksheet->set_row($ord_row,  undef, undef, 1, 1);
    # header row
    for my $idx (sort {$a <=> $b} keys %{$ord_headers}){
        $worksheet->write($ord_row,++$ord_col,$ord_headers->{$idx},$bold);
    }
    $worksheet->set_row($ord_row,  undef, undef, 1, 2);
    # items
    for my $pid (sort keys %{$objects}){
        $ord_col = 0;
        $worksheet->write(++$ord_row,$ord_col++,$objects->{$pid}->{description});
        
        for my $idx (sort {$a <=> $b} keys %{$ord_headers}){
            my $name = $ord_headers->{$idx} ;   
            if( exists $objects->{$pid}->{tags}->{$name} ){
                $worksheet->write($ord_row,$ord_col++,$objects->{$pid}->{tags}->{$name});
            } else { $ord_col++; }
        }    
        $worksheet->set_row($ord_row,  undef, undef, 1, 2);
    }
    return($ord_row+1);
};

sub tbalance_export{
    my ($self,$tbalance,$tdata) = @_ ;
    my ($file_path,$file_name) = get_new_file_path_name();
    # Create a new workbook 
    my $workbook = Spreadsheet::WriteExcel->new($file_path);
    my $bold     = $workbook->add_format(bold => 1);
    # Add worksheet
    my $worksheet = $workbook->add_worksheet('Export - Buh1.Uz');
    $worksheet->set_column('A:A', 30);
    # final
    $workbook->close();
    return(($file_path,$file_name)) if $self->param('type') eq '.xls' ;
    ($file_path,$file_name) = make_zipped_file(($file_path,$file_name,$self->('type')));
    return(($file_path,$file_name));
};

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

 M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
