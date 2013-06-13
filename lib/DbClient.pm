package DbClient; {

=encoding utf8

=head1 NAME

   Functions to work with client's database

=cut

use 5.012000;
use strict;
use warnings;
use utf8;
use Utils;
use DBI;
use DBD::SQLite;
use Data::Dumper; #for debug

my $DB_SQLite_TYPE  = 0;
my $DB_Pg_TYPE      = 2;
my $DB_CURRENT_TYPE = $DB_SQLite_TYPE;

my $SQLITE_FILE;

my $_production_mode = 1;
sub set_production_mode{ $_production_mode = shift; };
sub get_production_mode{ $_production_mode; };

sub warn_if{
    warn shift if get_production_mode ;
};

sub set_sqlite_file{
    my $file = shift;
    $SQLITE_FILE = Utils::get_root_path('db/client', "$file.db");
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


};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>


