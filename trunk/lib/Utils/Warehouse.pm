package Utils::Warehouse; {

=encoding utf8

=head1 NAME

    Database utilites 

=cut

use 5.012000;
use strict;
use warnings;
use utf8;
use Utils::Db ;
use Utils::Filter ;
use Data::Dumper ;

my $OBJECT_NAME  = 'warehouse object' ;
my $OBJECT_NAMES = 'warehouse objects' ;

sub object_name{ return($OBJECT_NAME); };
sub object_names{ return($OBJECT_NAMES); };
sub tag_object_name{ return("$OBJECT_NAME tag"); };
sub tag_object_names{ return("$OBJECT_NAMES tags"); };
sub remain_object_name{ return("$OBJECT_NAME remain"); };
sub remain_object_names{ return("$OBJECT_NAMES remains"); };

sub validate_id2edit{
    my $self = shift;
    my $id = $self->param('payload') ;
    if( !$id ){
        warn "Object not exists!";
        $self->redirect_to('/user/login?warning=data_not_found');
        return(0);
    }
    my $db = Utils::Db::client($self);
    my $objects = $db->get_objects({id => [$id]});
    if( !scalar(keys(%{$objects})) ){
        warn "Object not found!";
        $self->redirect_to('/user/login?warning=data_not_found');
        return(0);
    }
    return(1)
};

sub add_edit_post{
    my $self = shift ;
    my $data = form2data($self);
    if( validate($self,$data) ){
        my $id = Utils::Db::cdb_insert_or_update($self,$data);
        my $action = $self->stash('action') ;
        if( lc($action) eq 'add' ){
            $self->redirect_to("/warehouse/edit/$id") ;
            $self->stash('success' => 1);
        } else {
            $self->stash('success' => 1);
        }
            return(1);
    }
    $self->stash(error => 1);
    return(0) ;
};

sub form2data{
    my $self = shift;
    my $data = { 
        object_name => $self->param('oname'),
        creator     => Utils::User::current($self),
        } ;
    my @extra_fields = ('id','counting_direction') ;
    for my $extra_field (@extra_fields){    
    	$data->{$extra_field} = $self->param($extra_field) if $self->param($extra_field) ;
    }
    $data->{description} = Utils::trim $self->param('description')
        if Utils::trim $self->param('description');
    return($data)
};

sub validate{
    my ($self,$data) = @_ ;
    if( !exists $data->{description} ){
        $self->stash('description_class' => 'error');
        $self->stash('error' => 1);
        return(0);
    }
    return(1);
};

sub deploy_list_objects{
    my ($self,$name,$path) = @_;

    my $filter = Utils::Filter::get_filter($self);
    my $db = Utils::Db::client($self);
    my $objects ;
    my $fields = ['description','counting_field','counting_parent','counting_direction'] ;
    if( !$filter ){
        $objects = get_all_objects($self,$fields) ;
    } else {
        $objects = Utils::Db::get_filtered_objects2($self, {
                object_name   => object_name(),
                object_names  => object_names(),
                fields        => $fields,
                child_names   => [Utils::Tags::object_name()],
                filter_value  => $filter,
            });
        $self->stash( filter => $filter );
    }
    $self->stash( objects => $objects ) if scalar(keys(%{$objects}));
    return($objects);
};

sub deploy_remains_all{
    my ($self,$name,$path) = @_;

    my $filter = Utils::Filter::get_filter($self);
    my $sql = " SELECT DISTINCT id, value desription "
              . " FROM objects WHERE name = 'warehouse object' " 
              . " AND field = 'description' AND field = 'description' "
              . " AND id NOT IN (SELECT DISTINCT id FROM objects " 
              . " WHERE name = 'warehouse object' AND field = 'counting_parent'); " ;
    my $db = Utils::Db::client($self);
    my $sth = $db->get_from_sql( $sql ) ;
    my $ids = []; 
    my ($id, $description);
    $sth->bind_columns(\$id, \$description);
    while($sth->fetch){
        push @{$ids}, $id if !$filter || $description =~ /$filter/i ;
    }
    return({}) if !scalar(@{$ids}) ; # return empty hash ref
    # 2. Setup paginator
    my ($page,$pages,$pagesize) = Utils::Filter::setup_pages($self,scalar(@{$ids}));
    my $start_index = ($page - 1) * $pagesize ;
    my $end_index = $start_index + $pagesize - 1 ;
    # 3. Final actions
    my $rids = []; @{$rids} = (reverse @{$ids})[$start_index..$end_index];
    my $remains_objects = {};
    for my $rid (@{$rids}) {
        next if !$rid ;
        my ($object,$links) = get_clear_db_object($self,$rid);
        if( scalar(keys(%{$object})) ){
            $remains_objects->{$rid} = $object ;
            my($parent,$childs,$caclulated_counting) 
                    = calculated_counting($self,$rid);
             $remains_objects->{$rid}->{calculated_counting}
                    = $caclulated_counting ;
             $remains_objects->{$rid}->{calculated_childs_count}
                    = $childs ? scalar(keys(%{$childs})) : 0 ;
        }

    }
    $self->stash( remains_objects => $remains_objects ) if scalar(@{$rids});
    return($rids);
};

sub get_all_objects{
    my $self   = shift ;
    my $fields = shift ;
    my $db = Utils::Db::client($self) ;
    return $db->get_filtered_objects({
            self          => $self,
            name          => object_name(),
            names         => object_names(),
            exist_field   => 'description',
            filter_value  => undef,
            filter_prefix => " field='description' ",
            result_fields => $fields,
        });
};

sub update_counting_field{
    my $self = shift ;
    my $pid = $self->param('payload') ;
    my $counting_field_value = $self->param('counting_field');
    if( !$counting_field_value ){
        $self->redirect_to("/warehouse/edit/$pid?error=1&error_counting_field=error");
        return;
    }
    set_field($self,$pid,'counting_field',$counting_field_value);
    $self->redirect_to("/warehouse/edit/$pid?success=1");
};

sub set_field{
    my ($self,$pid,$field_name,$field_value) = @_ ;
    my $data = { 
        id          => $pid,
        object_name => object_name(),
        $field_name => $field_value,
    } ;
    Utils::Db::cdb_insert_or_update($self, $data) ;
};

sub clone_object{
    my $self = shift;
    my $pid  = $self->param('payload') ;
    # 1. Clone object
    my ($object_clone,$links) = get_clear_db_object($self,$pid);
    $object_clone->{description} = Utils::trim $self->param('description') 
        if Utils::trim $self->param('description');
    # 2. Clone tags
    my $tags_clone = {};
    if( $links ){
        for my $tagid (keys %{$links}){
            if( $links->{$tagid} eq tag_object_name() ){
                my($clone_tag,$clone_tag_links) = get_clear_db_object($self,$tagid) ;
                $tags_clone->{$tagid} = $clone_tag;
            }
        }
    }
    my $db = Utils::Db::client($self);
    my $dbh = $db->get_db_connection();
    $dbh->begin_work() ; # BEGIN TRANSACTION
    $dbh->{RaiseError} = 1 ;
    # 3.1 clone parent & tags
    my $new_pid ; my $new_tags_clone = {};
    eval {
        $new_pid = $db->insert($object_clone);
        # 3.2 clone tags
        for my $tagid (keys %{$tags_clone}){
            $new_tags_clone->{$tagid} = $db->insert($tags_clone->{$tagid});
            # make links
            $db->set_link($new_pid,$new_tags_clone->{$tagid});
        }
        $dbh->commit();    # END TRANSACTION
    };
    if ($@) {
        $self->redirect_to("/warehouse/edit/$pid?error=1");
        warn "Transaction aborted because $@";
        eval { $dbh->finish(); $dbh->rollback(); }; # ROLLBACK TRANSACTION
        return(undef);
    } else {
        # 3.3 create new counting_field, if exists
        if( scalar(keys(%{$tags_clone}))
            && exists($object_clone->{counting_field}) ){
            my $couting_tag_id = $object_clone->{counting_field} ;
            set_field($self,$new_pid,'counting_field'    ,$new_tags_clone->{$couting_tag_id});
            set_field($self,$new_pid,'counting_direction',$self->param('counting_direction') || '+');
            set_field($self,$new_pid,'counting_parent'   ,$self->param('counting_parent')    || $pid);
        }
        $self->redirect_to("/warehouse/edit/$new_pid?success=1");
    }
    $dbh->{RaiseError} = 0 ;
    return($new_pid);
};

sub get_clear_db_object{
    my ($self,$id) = @_ ; 
    return(undef) if !$self || !$id;
    my $objects = Utils::Db::cdb_get_objects($self, { id => [$id] });
    my $object  = $objects->{$id} ;
    my $clear_db_object = {};
    for my $key (keys %{$object}){
        $clear_db_object->{$key} = $object->{$key} if $key !~ /(^_|^id$)/ ;
    };
    return ($clear_db_object,(exists($object->{_link_}) ? $object->{_link_} : undef));
};

sub calculated_counting{
    my ($self,$id) = @_;
    return(undef) if !$self || !$id ;
    my $pid  = get_counting_parent_id($self, $id);
    my $db = Utils::Db::client($self);
    my $parent  = get_parent_and_counting_field_value($self,$pid);
    return(undef) if !$parent || !exists($parent->{counting_field_value}) ;
    my $pid_cfv = $parent->{counting_field_value} ;

    my $childs = get_childs_and_counting_field_value($self,object_name(),'counting_parent',$pid);
    my $result ;
    my $childs_eval_str = get_childs_counting_eval_str($self,$childs);
    my $eval_string;
    if( $pid_cfv ){
        $eval_string = "$pid_cfv" ;
        $eval_string .= $childs_eval_str if $childs_eval_str ;
        $result = eval $eval_string ;
        warn $@ if $@ ;
    }
    return($parent,$childs,$result || 0);
};

sub get_counting_parent_id{
    my ($self,$id) = @_ ;
    return(undef) if !$self || !$id ;
    my $objects = Utils::Db::cdb_get_objects($self,{ id => [$id], field => ['counting_parent']});
    return($objects->{$id}->{counting_parent}) 
        if exists($objects->{$id}) && exists($objects->{$id}->{counting_parent}) ;
    return $id;
};

sub get_parent_and_counting_field_value{
    my ($self,$pid) = @_ ;
    return(undef) if !$self || !$pid ;
    my $db = Utils::Db::client($self);
    my $objects = $db->get_objects({ id => [$pid], field => ['description','counting_field'] }) ;
    if( $objects && exists($objects->{$pid}) ){
        my $result = $objects->{$pid} ;
        $result->{counting_field_value} = get_linked_field_value($self,$pid,'counting_field','value') ;
        my $tagid = $result->{counting_field} ;
        my $tag_objects = $db->get_objects({ id => [$tagid], field => ['name','value'] }) ;
        if( $tag_objects && exists($tag_objects->{$tagid}) ){
            $result->{counting_field_object} = $tag_objects->{$tagid};
        }
        return($result);
    }
    return(undef);
};

sub get_childs_and_counting_field_value{
    my ($self,$object_name,$field_name,$field_value) = @_ ;
    return(undef) if !$self || !$object_name || !$field_name || !$field_value ;
    my $sql = "SELECT DISTINCT id FROM objects where name = '$object_name' AND field = '$field_name' AND value = '$field_value' ; ";
    my $db = Utils::Db::client($self);
    my $sth = $db->get_from_sql( $sql ) ;
    my $cid = undef;
    $sth->bind_col(1, \$cid);
    my $result = {};
    while($sth->fetch){
        my $childs = $db->get_objects({ id => [$cid], field => ['description','counting_field','counting_direction','counting_parent'] }) ;
        if( $childs && exists($childs->{$cid}) 
                    && exists($childs->{$cid}->{counting_direction}) 
                    && exists($childs->{$cid}->{counting_field}) ){
            $childs->{$cid}->{counting_field_value} = get_linked_field_value($self,$cid,'counting_field','value');
            $result->{$cid} = $childs->{$cid} ;
        }
    }
    return($result);
};

sub get_childs_counting_eval_str{
    my ($self,$childs) = @_ ;
    return(undef) if !$self || !$childs || !scalar(keys(%{$childs})) ;
    my $result = '';
    for my $cid (keys %{$childs}){
            $result .= "$childs->{$cid}->{counting_direction}" . $childs->{$cid}->{counting_field_value} ;
    }
    return($result);
};

sub get_linked_field_value{
    my ($self,$o1_id,$o1_o2_field_name,$o2_field_name) = @_ ;
    return(undef) if !$self || !$o1_id || !$o1_o2_field_name || !$o2_field_name ;
    my $o1_object = 
         Utils::Db::cdb_get_objects(
            $self, 
            { id => [$o1_id], field =>[$o1_o2_field_name] });
    return(undef) if !exists($o1_object->{$o1_id}) ||
                     !exists($o1_object->{$o1_id}->{$o1_o2_field_name}) ;
    my $o2_id = $o1_object->{$o1_id}->{$o1_o2_field_name};
    return(undef) if !$o2_id ;
    my $o2_object =
         Utils::Db::cdb_get_objects(
            $self, 
            { id => [$o2_id], field =>[$o2_field_name] });

    return(undef) if !exists($o2_object->{$o2_id}) ||
                     !exists($o2_object->{$o2_id}->{$o2_field_name}) ;
    return($o2_object->{$o2_id}->{$o2_field_name}) ;
};

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

 M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
