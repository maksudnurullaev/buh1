package Buh1::Documents; {

=encoding utf8

=head1 NAME

    Documents

=cut


use strict;
use warnings;
use utf8;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;
use Utils::Db;

my $OBJECT_NAME   = 'document';
my $OBJECT_NAMES  = 'documents';
my $OBJECT_FIELDS = ['account','bt','debet','credit','type','document number',
                     'date','Permitter','Permitter debet','Permitter INN',
                     'Permitter bank name','Permitter bank code','Currency amount',
                     'Beneficiary','Beneficiary credit','Beneficiary bank name',
                     'Beneficiary bank code','Currency amount in words',
                     'Details','Executive','Accounting manager'];

sub isValidUser{
    my $self = shift;
    if( !$self->is_user ){
        $self->redirect_to('/user/login');
        return;
    }
    return(1);
};

sub set_form_header{
    my $self = shift;
    my $parameters = {};
    my @headers = ('account','bt','debet','credit');
    for my $header (@headers){
        my $value = $self->param($header);
        if( $value ){
            $parameters->{$header} = $value;
            warn "Find proper value($value) for '$header'";
        }else{
            warn "Could not find proper value for '$header'";
            $self->stash( error => 1 );
            return;
        }
    }
    my $db = Db->new();
    for my $key (keys %{$parameters}){
        my $id = $parameters->{$key};
        if( !$id ){
            warn "No ID to linked object($key) defined!";
            $self->stash( error => 1 );
            return;
        }
        my $db_object = $db->get_objects({id => [$id]});
        if( !$db_object ){
            warn "No db object($id) found in database!";
            $self->stash( error => 1 );
            return;
        }
        Utils::Languages::generate_name($self,$db_object);
        $self->stash( $key => $db_object->{$id} );
    }
    return(1)   
};

sub list{
    my $self = shift;
    return if !isValidUser($self);

    my $db_client = Utils::Db::get_client_db($self);
    return if !$db_client;
};

sub validate{
    my $self = shift;
    my $isNew = shift;
    my $data = { 
        object_name => $OBJECT_NAME,
        creator => Utils::User::current($self),
    };
    for my $field_name (@{$OBJECT_FIELDS}){
        my $field_value = Utils::trim $self->param($field_name);
        if( $field_value ){
            $data->{$field_name} = $field_value;
        } else {
            $data->{error} = 1;
            $self->stash(($field_name . '_class') => 'error');
        }
    }
    return($data);
};

sub update{
    my $self = shift;
    return if !isValidUser($self);
    return if !set_form_header($self);

    my $isPost = ($self->req->method =~ /POST/);
    if( $isPost ){
        my $isNew = defined($self->param('docid'));
        my $data  = validate($self,$isNew);
        if( !exists($data->{error}) ){
           warn "Insert PART!"; 
        }
    }
};

1;

};

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
