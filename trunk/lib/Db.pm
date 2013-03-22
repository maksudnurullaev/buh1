package Db; {

=encoding utf8

=head1 NAME

   Db functions

=cut

use 5.012000;
use strict;
use warnings;
use utf8;
use Utils;
use DBI;
use DBD::SQLite;

my $DB_SQLite_TYPE  = 0;
my $DB_Pg_TYPE      = 2;
my $DB_CURRENT_TYPE = $DB_SQLite_TYPE;

my $SQLITE_FILE = Utils::get_root_path("db", "main.db");

sub get_sqlite_file{
    return($SQLITE_FILE);
};

sub get_db_connection{
    if($DB_CURRENT_TYPE == $DB_SQLite_TYPE){
        my $dbh = DBI->connect("dbi:SQLite:dbname=" . Db::get_sqlite_file(),"","");
        if(!defined($dbh)){
            warn $DBI::errstr;
            return(undef);
        }
        return($dbh);
    } elsif ($DB_CURRENT_TYPE == $DB_Pg_TYPE) {
        warn "Error:Pg: Not implemeted yet!";
        return(undef);
    } else {
        warn "Error:DB: Unknown db type!";
        return(undef);
    }
};

sub insert_object{
    my $hashref = shift;
    my $object_name;
    if(defined($hashref) && defined($hashref->{object_name})){
        $object_name = $hashref->{object_name};
    } else {
        warn "Error:Db:Insert: No object name!";
        return(undef);
    }
    if(scalar( keys %{$hashref}) == 1){
        warn "Error:Db:Insert: No data!";
        return(undef);
    }
    my $id = Utils::get_date_uuid();
    my $dbh = get_db_connection();
    my $sth = $dbh->prepare(
        "INSERT INTO objects (name,id,field,value) values(?,?,?,?);");
    for my $field (keys %{$hashref}){
        if( $field !~ /^object_name$/){
            $sth->execute($object_name,$id,$field,$hashref->{$field});
        }
    }
    return($id);
};

sub select_object{
    my $id = shift;
    if(!defined($id)){
        warn "Error:Db:Select: No id!";
        return(undef);
    }
    my $dbh = get_db_connection();
    $dbh->{FetchHashKeyName} = 'NAME_lc';
    my $sth = $dbh->prepare("SELECT name,id,field,value FROM objects WHERE id = ?");
    my($name,$field,$value,$id_current,$result);
    if($sth->execute($id)){
        $sth->bind_columns(\($name,$id,$field,$value));
        $id_current = '__NOTHING___';
        while ($sth->fetch) {
            if($id_current ne $id){
                $result->{$id} = { name => $name }; 
                $id_current = $id;
            }
            $result->{$id}{$field} = $value;
        }
    } else { warn $DBI::errstr; }

    return($result);
};

};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
