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
        my $dbh = DBI->connect("dbi:SQLite:dbname=" . Db::get_sqlite_file(),"","");
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

sub insert_object{
    my $hashref = shift;
    my $object_name;
    if(defined($hashref) 
            && defined($hashref->{object_name})
            && defined(Utils::trim($hashref->{object_name}))){
        $object_name = Utils::trim($hashref->{object_name});
    } else {
        warn_if "Error:Db:Insert: No object or object name!";
        return(undef);
    }
    if(scalar( keys %{$hashref}) == 1){
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
        if( $field !~ /^object_name$/){
            $sth->execute($object_name,$id,$field,$hashref->{$field});
        }
    }
    return($id);
};

sub select_object{
    my $id = shift;
    if(!defined($id)){
        warn_if "Error:Db:Select: No ID defined for search!";
        return(undef);
    }
    my $dbh = get_db_connection();
    if(!defined($dbh)){
        warn_if "Error:Db:Insert Could not connect to db!";
        return(undef);
    }
    $dbh->{FetchHashKeyName} = 'NAME_lc';
    my $sth = $dbh->prepare("SELECT name,id,field,value FROM objects WHERE id = ?");
    my($name,$field,$value,$id_current,$result) = (undef,undef,undef,"NONE",{});
    if($sth->execute($id)){
        $sth->bind_columns(\($name,$id,$field,$value));
        while ($sth->fetch) {
            if($id_current ne $id){
                $result->{$id} = { name => $name }; 
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
