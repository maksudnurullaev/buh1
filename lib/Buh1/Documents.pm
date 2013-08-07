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
use Utils::Digital;
use Encode;

my $OBJECT_NAME   = 'document';
my $OBJECT_NAMES  = 'documents';
my @OBJECT_FIELDS = ('object_name','account','bt','debet','credit','type','document number',
                     'date','permitter','permitter debet','permitter inn',
                     'permitter bank name','permitter bank code','currency amount',
                     'beneficiary','beneficiary credit','beneficiary bank name',
                     'beneficiary bank code','currency amount in words',
                     'details','executive','accounting manager');

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
        my $value = $self->param($header) || $self->stash($header);;
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
    my $id = shift;
    my $data = { object_name => $OBJECT_NAME };
    my @fields = @OBJECT_FIELDS;
    push(@fields, 'id') if $id;
    for my $field (@fields){
        my $value = Utils::trim $self->param($field);
        if( $value ){
            $data->{$field} = $value;
        } else {
            $data->{error} = 1;
            $self->stash(($field . '_class') => 'error');
        }
    }
    return($data);
};

sub update{
    my $self = shift;
    return if !isValidUser($self);

    my $isPost  = ($self->req->method =~ /POST/) && ( (!$self->param('post')) || ($self->param('post') !~ /^preliminary$/i) );
    my $id      = $self->param('docid');
    warn "DOCID = " . $id if defined $id;
    my $payload = $self->param('payload');
    my $bt      = $self->param('bt');
    if( $isPost ){
        my $data  = validate($self,$id);
        if( !exists($data->{error}) ){
            my $db_client = Utils::Db::get_client_db($self);
            if( defined $id ){
                warn "Is updatIs update!!! $id";
                if( $db_client->update($data) ){
                    $self->stash(success => 1);
                    $self->redirect_to("/documents/update/$payload?docid=$id");
                } else {
                    $self->stash(error => 1);
                    warn 'Could not update objects!';
                }
            } else {
                warn "Is new!!!";
                if( $id = $db_client->insert($data) ){
                    $self->redirect_to("/documents/update/$payload?docid=$id");
                } else {
                    $self->stash(error => 1);
                    warn 'Could not insert object!';
                }
            }
        } else {
            $self->stash( error => 1 );
        }
    }
    if( $id ){
        deploy_document($self,$id);
    } else {
        set_test_data($self);
    }
    set_form_header($self);
};

sub deploy_document{
    my ($self,$id) = @_;
    return if !$self || !$id;
    my $db_client = Utils::Db::get_client_db($self);
    my $objects = $db_client->get_objects({id=>[$id]});
    if( $objects && exists($objects->{$id}) ){
        my $document = $objects->{$id};
        for my $field (keys %{$document}){
            $self->stash($field => $document->{$field});
        }
    }
};

sub set_test_data{
    my $self = shift || return;
    my $number = int(rand(100));
    $self->stash( 'document number' => $number );
    $self->stash( 'permitter' => 'ООО "УЗБЕКЛОЙИХАСОЗЛАШ"' );
    $self->stash( 'permitter debet' => '01234567890123456789' );
    $self->stash( 'permitter inn' => '123456789' ); 
    $self->stash( 'permitter bank name' => 'ЧОАКБ ИнФинБанк' );
    $self->stash( 'permitter bank code' => '01041' );
    $number = int(rand(10000000));
    $self->stash( 'currency amount' => $number );
    $self->stash( 'beneficiary' => 'ОАО "Узбекистон Темирйуллари"' );
    $self->stash( 'beneficiary credit' => '99999999999999999999' );
    $self->stash( 'beneficiary bank name' => 'АИКБ "Ипак Йули"' );
    $self->stash( 'beneficiary bank code' => '14230' );
    $self->stash( 'currency amount in words' => Utils::Digital::rur_in_words($number) );
    $self->stash( 'details' => 'Оплата за установку кронштейна!' );
    $self->stash( 'executive' => 'Abdullaev Z.S.' );
    $self->stash( 'accounting manager' => 'Umarova I.M.' );

};

1;

};

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
