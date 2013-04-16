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

my $_production_mode = 1;
sub set_production_mode{ $_production_mode = shift; };
sub get_production_mode{ $_production_mode; };

sub warn_if{
    warn shift if get_production_mode ;
};

sub get_sqlite_file{
    return($SQLITE_FILE);
};

sub get_db_connection{
    if($DB_CURRENT_TYPE == $DB_SQLite_TYPE){
        my $dbh = DBI->connect("dbi:SQLite:dbname=" . Db::get_sqlite_file(),"","", {sqlite_unicode => 1});
        if(!defined($dbh)){
            warn_if $DBI::errstr;
            return(undef);
        }
        return($dbh);
    } elsif ($DB_CURRENT_TYPE == $DB_Pg_TYPE) {
        warn_if "Error:Pg: Not implemeted yet!";
        return(undef);
    } else {
        warn_if "Error:DB: Unknown db type!";
        return(undef);
    }
};

sub initialize{
    return(1) if(-e $SQLITE_FILE);
    if($DB_CURRENT_TYPE == $DB_SQLite_TYPE){
        my $connection = get_db_connection || die "Could not connect to SQLite database";
        if(defined($connection)){
            my @SQLITE_INIT_SQLs = (
                    "CREATE TABLE objects (name TEXT, id TEXT, field TEXT, value TEXT);'",
                    "CREATE INDEX i_objects ON objects (name, id, field);",
                );
            for my $sql (@SQLITE_INIT_SQLs){
                my $stmt = $connection->prepare($sql);
                $stmt->execute || die "Error:Db: Could not init database with: $sql";
            }   
            return(1);   
        } 
    } else {
        warn_if "Error:DB: Unknown db type!";
        return(undef);
    }
};

sub change_name{
    my ($new_name, $id) = @_;
    if( $new_name && $id ){
         my $dbh = Db::get_db_connection();
         return $dbh->do("UPDATE objects SET name = '$new_name' WHERE id = '$id' ;");
    }
    return;
};

sub del{
    my $id = shift;
    if( $id ){
        my $dbh = Db::get_db_connection();
        return $dbh->do("DELETE FROM objects WHERE id = '$id' ;");
    }
    return;
};

sub update{
    my ($hashref, $object_name, $id) = (shift, undef, undef);
    if(defined($hashref) 
            && defined($hashref->{object_name})
            && defined($hashref->{id})){
        $object_name = Utils::trim($hashref->{object_name});
        $id = $hashref->{id};
        delete $hashref->{id}; 
        delete $hashref->{object_name};
    } else {
        warn_if "Error:Db:Update: No object or object name or Id!";
        return(undef);
    }
    if(scalar( keys %{$hashref}) == 0){
        warn_if "Error:Db:Insert: No data!";
        return(undef);
    }
    my $dbh = get_db_connection();
    if(!defined($dbh)){
        warn_if "Error:Db:Insert Could not connect to db!";
        return(undef);
    }
    my $sth = $dbh->prepare(
        qq{ UPDATE objects SET value = ? WHERE name = ? AND id = ? AND field = ?; });
    for my $field (keys %{$hashref}){
        $sth->execute($hashref->{$field},$object_name,$id,$field);
    }
    return($id);
};

sub insert{
    my ($hashref, $object_name) = (shift, undef);
    if( defined($hashref) && defined($hashref->{object_name}) ){
        $object_name = $hashref->{object_name};
        delete $hashref->{object_name}; 
    } else {
        warn_if "Error:Db:Insert: No object or object name!";
        return(undef);
    }
    if(scalar( keys %{$hashref}) == 0){
        warn_if "Error:Db:Insert: No data!";
        return(undef);
    }
    my $id = Utils::get_date_uuid();
    my $dbh = get_db_connection();
    if(!defined($dbh)){
        warn_if "Error:Db:Insert Could not connect to db!";
        return(undef);
    }
    my $sth = $dbh->prepare(
        "INSERT INTO objects (name,id,field,value) values(?,?,?,?);");
    for my $field (keys %{$hashref}){
        $sth->execute($object_name,$id,$field,$hashref->{$field});
    }
    return($id);
};

sub select{
    my $id = shift;
    if(!defined($id) || !$id){
        warn_if "Error:Db:Select: No ID defined for search!";
        return(undef);
    }
    my $dbh = get_db_connection();
    if(!defined($dbh)){
        warn_if "Error:Db:Insert Could not connect to db!";
        return(undef);
    }
    $dbh->{FetchHashKeyName} = 'NAME_lc';
    my $sth = $dbh->prepare(
        "SELECT name,id,field,value FROM objects WHERE id = ? ORDER BY id;");
    my($name,$field,$value,$id_current,$result) = (undef,undef,undef,"NONE",{});
    if($sth->execute($id)){
        $sth->bind_columns(\($name,$id,$field,$value));
        while ($sth->fetch) {
            if($id_current ne $id){
                $result->{$id} = { object_name => $name }; 
                $id_current = $id;
            }
            $result->{$id}{$field} = $value;
        }
    } else { warn_if $DBI::errstr; }
    return($result);
};

sub select_distinct_many{
    my $where_ = shift;
    if(!defined($where_) || !$where_){
        warn_if "Error:Db:Select Distinct: No Where part defined!";
        return(undef);
    }
    my $dbh = get_db_connection();
    if(!defined($dbh)){
        warn_if "Error:Db:Insert Could not connect to db!";
        return(undef);
    }
    $dbh->{FetchHashKeyName} = 'NAME_lc';
    my $sth_str = sprintf 
        'SELECT DISTINCT name, id, field, value FROM objects %s ;', $where_;
    my $sth = $dbh->prepare($sth_str);
    my ($name,$field,$value,$id,$id_current,$result) = (undef,undef,undef,undef,"NONE",{});
    if($sth->execute){
        $sth->bind_columns(\($name,$id,$field,$value));
        while ($sth->fetch) {
            if($id_current ne $id){
                $result->{$id} = { object_name => $name }; 
                $id_current = $id;
            }
            $result->{$id}{$field} = $value;
        }
    } else { warn_if $DBI::errstr; }
    return($result);

};

};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
