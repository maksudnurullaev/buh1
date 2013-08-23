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

sub new {
    my $class = shift;
    my $self = { file => $SQLITE_FILE };
    return(bless $self, $class);
};

sub get_db_path{
    my $self = shift;
    return($SQLITE_FILE);
};

sub warn_if{
    warn shift if get_production_mode ;
};

sub is_valid{
    my $self = shift;
    return( $self->initialize ) if ! -e $self->get_db_path();
    return (1);
};

sub get_db_connection{
    my $self = shift;
    if($DB_CURRENT_TYPE == $DB_SQLite_TYPE){
        my $dbi_connection_string = "dbi:SQLite:dbname=" . $self->get_db_path();
        my $dbh = DBI->connect($dbi_connection_string,'','', {sqlite_unicode => 1});
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
    my $self = shift;
    return(1) if( -e $self->get_db_path() );
    if($DB_CURRENT_TYPE == $DB_SQLite_TYPE){
        my $connection = $self->get_db_connection() || die "Could not connect to SQLite database";
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
    my $self = shift;
    my ($new_name, $id) = @_;
    if( $new_name && $id ){
         my $dbh = $self->get_db_connection() || return;
         return $dbh->do("UPDATE objects SET name = '$new_name' WHERE id = '$id' ;");
    }
    return;
};

sub change_id{
    my $self = shift;
    my ($idold, $idnew) = @_;
    if( $idold && $idnew ){
        my $found = $self->get_objects({id => [$idnew]});
        if( $found && $self->object_valid($found->{$idnew}) ){
            warn "change_id:error Object with id '$idnew' already exists!";
            return;
        }

        my $dbh = $self->get_db_connection() || return;
        return $dbh->do("UPDATE objects SET id = '$idnew' WHERE id = '$idold' ;");
    }
    warn "change_id:error NEW or OLD id not defined!";
    return;
};

sub del{
    my $self = shift;
    my $id = shift;
    return if !$id;
    my $dbh = $self->get_db_connection() || return;
    return $dbh->do("DELETE FROM objects WHERE id = '$id' ;");
};

sub update{
    my $self = shift;
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
    my $dbh = $self->get_db_connection()  || return;
    my $data_old = $self->get_objects({id => [$id]});
    my $sth_insert = $dbh->prepare(
        qq{ INSERT INTO objects (name,id,field,value) values(?,?,?,?); } );
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
    my $self = shift;
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
    my $id = $hashref->{id} || Utils::get_date_uuid();
    my $dbh = $self->get_db_connection() || return;
    my $sth = $dbh->prepare(
        "INSERT INTO objects (name,id,field,value) values(?,?,?,?);");
    for my $field (keys %{$hashref}){
        $sth->execute($object_name,$id,$field,$hashref->{$field});
    }
    return($id);
};

sub object_valid{
    my $self = shift;
    my $object = shift;
    return(undef) if !$object;
    for my $field (keys %{$object}){
        return(1) if $field !~ /^_/ ;
    }
    return(undef);
};

sub format_statement2hash_objects{
    my $self = shift;
    my $sth = shift;
    return {} if !$sth;
    my($name,$id,$field,$value,$result) = (undef,undef,undef,undef,{});
    $sth->bind_columns(\($name,$id,$field,$value));
    while ($sth->fetch) {
        $result->{$id} = {} if !exists($result->{$id});
        if( $name =~ /^_/ ){ # extended field name!!!
            $result->{$id}{$name} = {} if !exists($result->{$id}->{$name});
            $result->{$id}{$name}{$value} = $field;
            if( exists $result->{$id}{$name}{$field} ) {
                $result->{$id}{$name}{$field}++; 
            }else{
                $result->{$id}{$name}{$field} = 1;
            }
        } else {
            $result->{$id} = { object_name => $name, id => $id} 
                if !exists($result->{$id}->{object_name}); 
            $result->{$id}{$field} = $value;
        }
    }
    return($result) if scalar(keys%{$result});
    return(undef);
};

sub get_from_sql{
    my $self = shift;
    my $sql_string = shift;
    return(undef) if !$self || !$sql_string;

    my $dbh = $self->get_db_connection() || return(undef) ;
    $dbh->{FetchHashKeyName} = 'NAME_lc';
    my $sth = $dbh->prepare($sql_string);
    if( scalar(@_) ){
        if( $sth->execute(@_) ){
            return($sth);
        } else { warn_if $DBI::errstr; }
    } else {
        if( $sth->execute ){
            return($sth);
        } else { warn_if $DBI::errstr; }
    }
    return(undef);

};

sub format_sql_parameters{
    my $self = shift;
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
    my $where_part = $self->format_sql_where_part($parameters);
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
    my $self = shift;
    my $parameters = shift;
    my $result = '';
    my $dbh = $self->get_db_connection() || return;
    my @fields = qw(id name field value);
    for my $field(@fields){
        if( exists($parameters->{$field}) && $parameters->{$field} ){
            $result .= " AND " if $result;
            my $values = $parameters->{$field};
            my $count = scalar(@{$values}); # count of parameters
            if( $count == 1 ){
                $result .= " $field = " . $dbh->quote($values->[0]) . " ";
            } elsif( $count == 3 && $values->[0] =~ /^between$/i ) {
                $result = " ($field BETWEEN " 
                    . $dbh->quote($values->[1]) . " AND "
                    . $dbh->quote($values->[2]) . ") ";
            } else {
                $result .= 
                    " $field IN (" . join(",", map { $dbh->quote($_) } @{$values}) 
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
    my $self = shift;
    my $parameters = shift;
    if( ref($parameters) ne "HASH" ){
        warn "Parameters should be hash!";
        return;
    }
    my $dbh = $self->get_db_connection() || return;
    $dbh->{FetchHashKeyName} = 'NAME_lc';
    my ($sth,$sql_string) = (undef, $self->format_sql_parameters($parameters));
    $sth = $dbh->prepare($sql_string);
    if( $sth->execute ){
        return($self->format_statement2hash_objects($sth));
    } else { warn_if $DBI::errstr; }
    return;
};

sub get_filtered_objects{
    my $self          = shift;
    my $parameters    = shift;
    my $app           = $parameters->{self};
    my $name          = $parameters->{name};
    my $names         = $parameters->{names};
    my $exist_field   = $parameters->{exist_field};
    my $filter_value  = $parameters->{filter_value};
    my $filter_prefix = $parameters->{filter_prefix};
    my $result_fields = $parameters->{result_fields};
    my $filter_where;
    my $result;
    if( $filter_value ) {
        $app->stash(filter => $filter_value) if $filter_value;
        if( $filter_prefix ){
            $filter_where = " $filter_prefix AND value LIKE '%$filter_value%' escape '\\' ";
        } else {
            $filter_where = " value LIKE '%$filter_value%' escape '\\' ";
        }
        $result = $self->get_counts({name=>[$name], add_where=>$filter_where});
    } else {
        $result = $self->get_counts({name=>[$name],field=>[$exist_field]}); 
    }
    return if !$result; # count is 0
    #paginator
    my $paginator = Utils::get_paginator($app,$names,$result);
    $app->stash(paginator => $paginator);        
    my ($limit,$offset) = (" limit $paginator->[2] ",
            $paginator->[2] * ($paginator->[0] - 1));
    $limit .= " offset $offset " if $offset ; 
    # find real records if exist
    if( $filter_value ) {
        $result = $self->get_objects({
            name      => [$name], 
            add_where => $filter_where,
            limit     => $limit});
    } else {
        $result = $self->get_objects({
            name  => [$name],
            field => [$exist_field],
            limit => $limit}); 
    }
    # final
    map { $result->{$_} = 
        $self->get_objects({
            name  => [$name],
            field => $result_fields})->{$_} }
        keys %{$result};
    return($result);
};

sub get_counts{
    my $self = shift;
    my $parameters = shift;
    if( ref($parameters) ne "HASH" ){
        warn "Parameters should be hash!";
        return;
    }
    my $dbh = $self->get_db_connection() || return;
    $dbh->{FetchHashKeyName} = 'NAME_lc';
    my $where_part = $self->format_sql_where_part($parameters);
    my($count) = $dbh->selectrow_array(" SELECT COUNT(*) FROM objects WHERE $where_part ;");
    return($count);
};

# -= access betweeen two objects =-
#   sort when incoming order by less id inserted always in ID colomn
#   whane greater id always inserted in FIELD column
#   ALWAYS: ID < FIELD
# ==============================
# | name   | id  | field | value |
# ==============================
# | access | id1 | id2   | value |
# ------------------------------
sub get_linked_value{
    my $self = shift;
    my ($name,$id1,$id2) = @_;
    return if(!$name || !$id1 || !$id2 || ($id1 eq $id2) );
    ($id1,$id2) = ($id2,$id1) if $id1 gt $id2; # impotant test & swap
    my $dbh = $self->get_db_connection() || return;
    $dbh->{FetchHashKeyName} = 'NAME_lc';
    my $sth_str = 
        "SELECT value FROM objects WHERE name=? AND id=? AND field=? ;";
    my $sth = $dbh->prepare($sth_str);
    if($sth->execute($name,$id1,$id2)){
        my $value;
        $sth->bind_columns(\($value));
        if($sth->fetch){
            return($value);
        }
        return(undef);
    } 
    warn_if $DBI::errstr; 
    return(undef); # some error happens
};

sub get_user{
    my $self = shift;
    my $email = shift;
    return(undef) if !$email;

    my $users = $self->get_objects({
        name  =>['user'],
        add_where => " field='email' AND value='$email' "
        });
    my @ids = keys %{$users};
    my $count = scalar(@ids);
    if( !$count ){
        warn "User with email '$email' not exist";
        return(undef);
    }
    if( scalar(@ids) != 1 ){
        warn "User with email '$email' not unique: $count!";
        return(undef);
    }
    # make map
    my $user_id = $ids[0];
    $users = $self->get_objects({
        name  =>['user'],
        field =>['email','password','extended_right'], 
        add_where => " name='user' AND id='$user_id' "
        });
    return(undef) if !$users ||
        !exists($users->{$user_id}) ||
        !exists($users->{$user_id}{password}) ;
    return($users->{$user_id});
};

sub set_linked_value{
    my $self = shift;
    my ($name,$id1,$id2,$value) = @_;
    return if( !$name || !$id1 || !$id2 || !$value || ($id1 eq $id2) );
    ($id1,$id2) = ($id2,$id1) if $id1 gt $id2; # impotant test & swap
    my $dbh = $self->get_db_connection() || return;
    if ( get_linked_value($name,$id1,$id2) ) {
        my $sth = $dbh->prepare(
            "UPDATE objects SET value = ? WHERE name =? AND id = ? AND field =? ;");
        return(0) if !$sth->execute($value,$name,$id1,$id2);
    } else {
        my $sth = $dbh->prepare(
            "INSERT INTO objects (name,id,field,value) values(?,?,?,?);");
        return(0) if !$sth->execute($name,$id1,$id2,$value);
    }
    return(1);
};

sub del_linked_value{
    my $self = shift;
    my ($name,$id1,$id2) = @_;
    return if( !$name || !$id1 || !$id2 );
    ($id1,$id2) = ($id2,$id1) if $id1 gt $id2; # impotant test & swap
    my $dbh = $self->get_db_connection() || return;
    return 
        $dbh->do("DELETE FROM objects WHERE name='$name' AND id='$id1' AND field='$id2';")
};

# -= links betweeen two objects =-
# ==============================
# | name | id  | field | value |
# ==============================
# | link | id1 | name2 | id2   |
# ------------------------------
sub exists_link{
    my $self = shift;
    my ($id1,$id2) = @_;
    return if( !$id1 || !$id2 );
    my $dbh = $self->get_db_connection() || return;
    $dbh->{FetchHashKeyName} = 'NAME_lc';
    my $sth_str = 
        "SELECT COUNT(*) FROM objects WHERE name=? AND id=? AND value=? ;";
    my $sth = $dbh->prepare($sth_str);
    if($sth->execute($LINK_OBJECT_NAME,$id1,$id2)){
        my($count) = $sth->fetchrow_array;
        return $count; 
    } 
    warn_if $DBI::errstr; 
    return(undef); # some error happens
};

sub set_link{
    my ($self,$name,$id,$link_name,$link_id) = @_;
    return(0) if( !$self || !$name || !$id || !$link_name || !$link_id );
    return(1) if exists_link($id,$link_id);

    my $dbh = $self->get_db_connection() || return;
    my $sth = $dbh->prepare(
        'INSERT INTO objects (name,id,field,value) values(?,?,?,?);');
    return(0) if !$sth->execute($LINK_OBJECT_NAME,$id,$link_name,$link_id);
    return(0) if !$sth->execute($LINK_OBJECT_NAME,$link_id,$name,$id);
    return(1);
};

sub attach_links{
    my ($self,$result,$links_name,$link_name,$fields) = @_;
    for my $id (keys %{$result}){
        my $links = $self->get_links($id,$link_name, $fields);
        for my $link_id (keys %{$links}){
            $result->{$id}->{$links_name} = {} 
                if !exists($result->{$id}->{$links_name});
            my $link_object = 
                $self->get_objects({id=>[$link_id],name=>[$link_name],field=>$fields});
            $result->{$id}{$links_name}{$link_id} = $link_object->{$link_id}
                if $link_object;   
        } 
    }
};

sub get_links{
    my ($self,$id1,$name2,$fields) = @_;
    return if( !$name2 || !$id1 );
    my $dbh = $self->get_db_connection() || return;
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
                $self->get_objects({id=>[$link_id],field=>$fields})
                : $self->get_objects({id=>[$link_id]}));
            $result->{$link_id} = $object->{$link_id} if $object;
        }
    } else { warn_if $DBI::errstr; }
    return($result) if scalar keys %{$result};
    return(undef);
};

sub get_difference{
    my($self,$id,$link_object_name,$field) = @_;
    my ($all_,$links_) = (
        $self->get_objects({name=>[$link_object_name], field=>[$field]}),
        $self->get_links($id, $link_object_name, [$field]) );
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
    my ($self,$id1,$id2) = @_;
    return if( !$id1 || !$id2 );
    my $dbh = $self->get_db_connection() || return;
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


