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

    my $isPost  = ($self->req->method =~ /POST/) && ( (!$self->param('post')) || ($self->param('post') !~ /^preliminary$/i) );
    my $id      = $self->param('docid');
    my $isNew   = !$id; 
    my $payload = $self->param('payload');
    my $bt      = $self->param('bt');
    if( $isPost ){
        my $data  = validate($self,$isNew);
        if( !exists($data->{error}) ){
            my $db_client = Utils::Db::get_client_db($self);
            if( $isNew )
                if( $id = $db_client->insert($data) ){
                    $self->redirect_to("/documents/update/$payload");
                }
            } else {
                $self->stash(error => 1);
                warn 'Users:add:error: could not add new user!';
            }
            if( $db_client->insert($data) ){
                $self->redirect_to('users/list');
            }
        }
    } elsif( $isNew ){
        set_test_data($self);
    }
    set_form_header($self);
};

sub set_test_data{
    my $self = shift || return;
    $self->stash( number => 1);
    $self->stash( 'document number' => '121' );
    $self->stash( 'Permitter' => 'ООО "Узбек лойиха созлаш бошкармаси"');
    $self->stash( 'Permitter debet' => 'Дебет счетимиз');
    $self->stash( 'Permitter INN' => 'ИНН-миз'); 
#                     'Permitter bank name','Permitter bank code','Currency amount',
#                     'Beneficiary','Beneficiary credit','Beneficiary bank name',
#                     'Beneficiary bank code','Currency amount in words',
#                     'Details','Executive','Accounting manager'];

};

1;

};

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
