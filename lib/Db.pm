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
use Data::Dumper; #for debug

my $DB_SQLite_TYPE  = 0;
my $DB_Pg_TYPE      = 2;
my $DB_CURRENT_TYPE = $DB_SQLite_TYPE;

my $SQLITE_FILE = Utils::get_root_path("db", "main.db");
my $LINK_OBJECT_NAME = '_link_';

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
         my $dbh = Db::get_db_connection() || return;
         return $dbh->do("UPDATE objects SET name = '$new_name' WHERE id = '$id' ;");
    }
    return;
};

sub del{
    my $id = shift;
    return if !$id;
    my $dbh = get_db_connection() || return;
    return $dbh->do("DELETE FROM objects WHERE id = '$id' ;");
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
    my $dbh = get_db_connection()  || return;
    my $data_old = get_objects({id => [$id]});
    my $sth_insert = $dbh->prepare(
        qq{ INSERT INTO objects (name,id,field,value) values(?,?,?,?);} );
    my $sth_update = $dbh->prepare(
        qq{ UPDATE objects SET value = ? WHERE name = ? AND id = ? AND field = ?; });
    for my $field (keys %{$hashref}){
        if( exists $data_old->{$id}->{$field} ) { # check if such field exits already!
            $sth_update->execute($hashref->{$field},$object_name,$id,$field);
        } else {
            $sth_insert->execute($object_name,$id,$field,$hashref->{$field});
        }
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
    my $dbh = get_db_connection() || return;
    my $sth = $dbh->prepare(
        "INSERT INTO objects (name,id,field,value) values(?,?,?,?);");
    for my $field (keys %{$hashref}){
        $sth->execute($object_name,$id,$field,$hashref->{$field});
    }
    return($id);
};

sub format_statement2hash_objects{
    my $sth = shift;
    return {} if !$sth;
    my($name,$id,$field,$value,$result) = (undef,undef,undef,undef,{});
    $sth->bind_columns(\($name,$id,$field,$value));
    while ($sth->fetch) {
        $result->{$id} = {} if !exists($result->{$id});
        if( $name =~ /^_/ ){ # extended field name!!!
            $result->{$id}->{$name} = {} if !exists($result->{$id}->{$name});
            $result->{$id}->{$name}->{$value} = $field;
        } else {
            $result->{$id} = { object_name => $name } 
                if !exists($result->{$id}->{object_name}); 
            $result->{$id}{$field} = $value;
        }
    }
    return($result) if scalar(keys%{$result});
    return;
};

sub format_sql_parameters{
    my $parameters = shift;
    if( !$parameters || scalar(keys %{$parameters}) == 0){
        warn "No parameters!";
        return;
    }
    my $result;
    if(exists $parameters->{distinct}){
        $result = ' SELECT DISTINCT name,id,field,value FROM objects ';
    } else {
        $result = ' SELECT name,id,field,value FROM objects ';
    }
    my $where_part = format_sql_where_part($parameters);
    $result .= " WHERE $where_part " if $where_part;
    if( exists $parameters->{order} ){
        $result .= " $parameters->{order} ";
    } else {
        $result .= " ORDER BY id DESC ";
    }
    if( exists $parameters->{limit} ){
        $result .= " $parameters->{limit} ";
    } 
    return("$result ;");
};

sub format_sql_where_part{
    my $parameters = shift;
    my $result = '';
    my $dbh = get_db_connection() || return;
    my @fields = qw(id name field);
    for my $field(@fields){
        if( exists($parameters->{$field}) && $parameters->{$field} ){
            $result .= " AND " if $result;
            if( scalar(@{$parameters->{$field}}) == 1 ){
                $result .= " $field = " . $dbh->quote($parameters->{$field}->[0]) . " ";
            } else {
                $result .= 
                    " $field IN (" . join(",", map { $dbh->quote($_) } @{$parameters->{$field}}) 
                    . ") ";
            }
        }
    }
    if( exists $parameters->{add_where} ){
        if( $result ){
            $result .= " AND $parameters->{add_where} "; 
        } else {
            $result .= " WHERE $parameters->{add_where} ";
        }
    }
    return($result);
};

sub get_objects{
    my $parameters = shift;
    if( ref($parameters) ne "HASH" ){
        warn "Parameters should be hash!";
        return;
    }
    my $dbh = get_db_connection() || return;
    $dbh->{FetchHashKeyName} = 'NAME_lc';
    my ($sth,$sql_string) = (undef, format_sql_parameters($parameters));
#    warn $sql_string;
    $sth = $dbh->prepare($sql_string);
    if( $sth->execute ){
        return(format_statement2hash_objects($sth));
    } else { warn_if $DBI::errstr; }
    return;
};

sub get_counts{
    my $parameters = shift;
    if( ref($parameters) ne "HASH" ){
        warn "Parameters should be hash!";
        return;
    }
    my $dbh = get_db_connection() || return;
    $dbh->{FetchHashKeyName} = 'NAME_lc';
    my $where_part = format_sql_where_part($parameters);
    my($count) = $dbh->selectrow_array(" SELECT COUNT(*) FROM objects WHERE $where_part ;");
#    warn " SELECT COUNT(*) FROM objects WHERE $where_part ;";
    return($count);
};

# -= LINKS betweeen two objects =-
# ==============================
# | NAME | ID  | FIELD | VALUE |
# ==============================
# | link | id1 | name2 | id2   |
# ------------------------------
sub exists_link{
    my ($id1,$id2) = @_;
    return if( !$id1 || !$id2 );
    my $dbh = get_db_connection() || return;
    $dbh->{FetchHashKeyName} = 'NAME_lc';
    my $sth_str = 
        "SELECT COUNT(*) FROM objects WHERE name=? AND id=? AND value=? ;";
    my $sth = $dbh->prepare($sth_str);
    my ($field,$value,$result) = (undef,undef,[]);
    if($sth->execute($LINK_OBJECT_NAME,$id1,$id2)){
        my($count) = $sth->fetchrow_array;
        return $count; 
    } 
    warn_if $DBI::errstr; 
    return(-1); # some error happens
};

sub set_link{
    my ($name,$id,$link_name,$link_id) = @_;
    return(0) if( !$name || !$id || !$link_name || !$link_id );
    return(1) if exists_link($id,$link_id);

    my $dbh = get_db_connection() || return;
    my $sth = $dbh->prepare(
        'INSERT INTO objects (name,id,field,value) values(?,?,?,?);');
    return(0) if !$sth->execute($LINK_OBJECT_NAME,$id,$link_name,$link_id);
    return(0) if !$sth->execute($LINK_OBJECT_NAME,$link_id,$name,$id);
    return(1);
};

sub attach_links{
    my ($result,$links_name,$link_name,$fields) = @_;
    for my $id (keys %{$result}){
        my $links = Db::get_links($id,$link_name, $fields);
        for my $link_id (keys %{$links}){
            $result->{$id}->{$links_name} = {} 
                if !exists($result->{$id}->{$links_name});
            my $link_object = 
                Db::get_objects({id=>[$link_id],name=>[$link_name],field=>$fields});
            $result->{$id}->{$links_name}->{$link_id} = $link_object->{$link_id}
                if $link_object;
        } 
    }
};

sub get_links{
    my ($id1,$name2,$fields) = @_;
    return if( !$name2 || !$id1 );
    my $dbh = get_db_connection() || return;
    $dbh->{FetchHashKeyName} = 'NAME_lc';
    my $sth_str = 
        "SELECT DISTINCT value FROM objects WHERE name=? AND id=? AND field=? ;";
    my $sth = $dbh->prepare($sth_str);
    my ($link_id,$result) = (undef,{});
    if($sth->execute($LINK_OBJECT_NAME,$id1, $name2)){
        $sth->bind_columns(\($link_id));
        while ($sth->fetch){
            my $object;
            $object = ($fields ?
                get_objects({id=>[$link_id],field=>$fields})
                : get_objects({id=>[$link_id]})->{$link_id});
            $result->{$link_id} = $object->{$link_id} if $object;
        }
    } else { warn_if $DBI::errstr; }
    return($result);
};

sub get_difference{
    my($id,$link_object_name,$field) = @_;
    my ($all_,$links_) = (
        Db::get_objects({name=>[$link_object_name], field=>[$field]}),
        Db::get_links($id, $link_object_name, [$field]) );
    my ($all,$links) = ([],[]);
    for my $link_id( keys %{$links_}){
        push @{$links}, [$links_->{$link_id}->{$field} => $link_id]
            if exists($all_->{$link_id});
    }
    for my $all_id(keys %{$all_}){
        push @{$all}, [$all_->{$all_id}->{$field} => $all_id]
            if !exists($links_->{$all_id}) ;
    }
    return($all,$links);
};

sub del_link{
    my ($id1,$id2) = @_;
    return if( !$id1 || !$id2 );
    my $dbh = get_db_connection() || return;
    $dbh->do(
        "DELETE FROM objects WHERE name='$LINK_OBJECT_NAME' AND id = '$id1' AND value = '$id2' ;");
    return $dbh->do(
        "DELETE FROM objects WHERE name='$LINK_OBJECT_NAME' AND id = '$id2' AND value = '$id1' ;");
};

};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
