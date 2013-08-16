package Buh1::Tbalance; {
use Mojo::Base 'Mojolicious::Controller';

sub isValidUser{
    my $self = shift;
    if( !$self->is_user ){
        $self->redirect_to('/user/login');
        return;
    }
    return(1);
};

sub validate{
    my $self = shift;
    my $id = shift;
    my @fields = ('start_date','end_date');
    my $data = {};
    for my $field (@fields){
        my $value = Utils::trim $self->param($field);
        if( $value ){
            $data->{$field} = $value;
        } else {
            $data->{error} = 1;
            $self->stash(($field . '_class') => 'error');
        }
    }
};

sub page {
    my $self = shift;
    return if !isValidUser($self);
    my $isPost  = ($self->req->method =~ /POST/);

    if( $isPost && (my $data = validate($self)) ){
    }
}

1;

};
