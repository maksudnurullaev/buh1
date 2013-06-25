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

sub new {
    my $class = shift;
    my $file = shift;
    my $self = { file => $file };
    bless $self, $class;
    return($self);
};

sub get_db_path{
    my $self = shift;
    Utils::get_root_path('db/clients', "$self->{file}.db");
};

sub is_valid{
    my $self = shift;
    if( ! -e $self->get_db_path ){
        return( $self->initialize );
    }
    return (1);
};

sub get_db_connection{
    my $self = shift;
    if($DB_CURRENT_TYPE == $DB_SQLite_TYPE){
        my $dbh = DBI->connect("dbi:SQLite:dbname=" . $self->get_db_path,"","", {sqlite_unicode => 1});
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

sub initialize{
    my $self = shift;
    if($DB_CURRENT_TYPE == $DB_SQLite_TYPE){
        my $connection = $self->get_db_connection || die "Could not connect to SQLite database";
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
        warn "Error:DB: Unknown db type!";
        return(undef);
    }
};


};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>


