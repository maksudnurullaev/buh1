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
use Utils::Filter;
use Utils::Digital;
use Utils::Documents;
use Encode;

my $OBJECT_NAME   = 'document';
my $OBJECT_NAMES  = 'documents';
my @OBJECT_FIELDS = ('object_name','account','bt','debet','credit','type','document number',
                     'date','permitter','permitter debet','permitter inn',
                     'permitter bank name','permitter bank code','currency amount',
                     'beneficiary','beneficiary credit','beneficiary bank name',
                     'beneficiary bank code','currency amount in words',
                     'details','executive','accounting manager');
my @OBJECT_HEADER_FIELDS = ('docid','account','bt','debet','credit');

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
    if( $db_client ){
        select_objects($self,$db_client,$OBJECT_NAME,'');
    } else {
        $self->reditect_to('desktop/select_company');
    }
};

sub redirect2list_or_path{
    my $self = shift;
    if ( $self->param('path') ){
        $self->redirect_to($self->param('path'));
        return;
    }
    $self->redirect_to("$OBJECT_NAMES/list");
};

sub pagesize{
    my $self = shift;
    Utils::Filter::pagesize($self,$OBJECT_NAMES);
    redirect2list_or_path($self);
};

sub page{
    my $self = shift;
    Utils::Filter::page($self,$OBJECT_NAMES);
    redirect2list_or_path($self);
};

sub nofilter{
    my $self = shift;
    Utils::Filter::nofilter($self,"$OBJECT_NAMES/filter");
    redirect2list_or_path($self);
};

sub filter{
    my $self = shift;
    Utils::Filter::filter($self,$OBJECT_NAMES);
    redirect2list_or_path($self);
};

sub select_objects{
    my ($self,$db,$name,$path) = @_;

    my $filter    = $self->session->{"$OBJECT_NAMES/filter"};
    my $objects = $db->get_filtered_objects({
            self          => $self,
            name          => $name,
            names         => $OBJECT_NAMES,
            exist_field   => 'bt',
            filter_value  => $filter,
            filter_prefix => " field NOT IN('bt','debet','credit','type','account') ",
            result_fields => ['document number', 'currency amount','details','date','account'],
            path          => ''
        });
    $self->stash(path  => $path);
    $self->stash(documents => $objects) if $objects && scalar(keys %{$objects});
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
    # recalculate amount if needs
    my $currency_amount = $data->{'currency amount'};
    my $currency_amount_in_words = Utils::Digital::rur_in_words($currency_amount);
    if( $id ){
        my $old_currency_amount = $self->param('old currency amount');
        if( !$old_currency_amount || ($currency_amount && ($currency_amount ne $old_currency_amount)) ){
            $data->{'currency amount in words'} =  Utils::Digital::rur_in_words($currency_amount);
            $self->stash('currency amount in words' => Utils::Digital::rur_in_words($currency_amount));
        }
    } else {
        $data->{'currency amount in words'} =  Utils::Digital::rur_in_words($currency_amount) ;
        $self->param('currency amount in words' => Utils::Digital::rur_in_words($currency_amount)) ;
    }
    # check for document number existance
    if( Utils::Documents::document_number_exist($self,$data->{'document number'},$id) ){
        $data->{error} = 1;
        $self->stash('document number_class' => 'error');
    }
    return($data);
};

sub validate_document_header{
    my $self = shift;
    my $result = {};
    for my $header (@OBJECT_HEADER_FIELDS){
        my $value = $self->param($header);
        if( !$value ){
            warn "No value found for mandatory $header field";
            return;
        }
        $result->{$header} = $value;
    }
    $result->{object_name} = $OBJECT_NAME;
    $result->{id} = $result->{docid};
    delete $result->{docid};
    return($result);
};

sub update_document_header{
    my $self = shift;
    return if !isValidUser($self);

    if( my $data = validate_document_header($self) ){
        my $db_client = Utils::Db::get_client_db($self);
        if( $db_client->update($data) ){
            $self->stash(success => 1);
        } else {
            $self->stash(error => 1);
            warn 'Could not update objects!';
        }
    }
    my $payload = $self->param("payload");
    my $docid = Utils::Documents::detach($self);
    $self->redirect_to("/documents/update/$payload?docid=$docid");
};

sub cancel_update_document_header{
    my $self = shift;
    return if !isValidUser($self);

    my $payload = $self->param("payload");
    my $docid = Utils::Documents::detach($self);
    $self->redirect_to("/documents/update/$payload?docid=$docid");
};

sub update{
    my $self = shift;
    return if !isValidUser($self);

    my $isPost  = ($self->req->method =~ /POST/) && ( (!$self->param('post')) || ($self->param('post') !~ /^preliminary$/i) );
    my $id      = $self->param('docid');
    my $payload = $self->param('payload');
    my $bt      = $self->param('bt');
    if( $id ){
        deploy_document($self,$id);
    } else {
        set_new_data($self);
    }
    set_form_header($self);
    if( $isPost ){
        my $data  = validate($self,$id);
        if( !exists($data->{error}) ){
            my $db_client = Utils::Db::get_client_db($self);
            if( defined $id ){
                if( $db_client->update($data) ){
                    $self->stash(success => 1);
                    $self->redirect_to("/documents/update/$payload?docid=$id&success=1");
                } else {
                    $self->stash(error => 1);
                    warn 'Could not update objects!';
                }
            } else {
                if( $id = $db_client->insert($data) ){
                    $self->redirect_to("/documents/update/$payload?docid=$id&success=1");
                } else {
                    $self->stash(error => 1);
                    warn 'Could not insert object!';
                }
            }
        } else {
            $self->stash( error => 1 );
        }
    }
};

sub deploy_document{
    my ($self,$id) = @_;
    return if !$self || !$id;
    my $db_client = Utils::Db::get_client_db($self);
    if( $db_client ){
        my $objects = $db_client->get_objects({id=>[$id]});
        if( $objects && exists($objects->{$id}) ){
            my $document = $objects->{$id};
            for my $field (keys %{$document}){
                $self->stash($field => $document->{$field});
            }
        }
    }
};

sub set_new_data{
    my $self = shift || return;
    my $user = Utils::User::current($self);
    return if !$user;
    my $number = Utils::Documents::get_document_number_next($self);
    $self->stash( 'document number' => $number );
    # for demo quick filling
    return if index($user,'maksud.nurullaev@gmail.com') == -1 && index($user,'demo@buh1.uz') == -1 ; 
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
    $self->stash( 'details' => 'Оплата за установку кронштейна!' );
    $self->stash( 'executive' => 'Петров И.У.' );
    $self->stash( 'accounting manager' => 'Камолова К.С.' );

};

1;

};

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
