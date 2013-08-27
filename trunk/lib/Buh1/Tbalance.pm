package Buh1::Tbalance; {
use Mojo::Base 'Mojolicious::Controller';
use Utils::Documents;
use Data::Dumper;

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
    my $data = {};
    validate_dates($self, $data);
    return($data)
};

sub validate_dates{
    my ($self,$data) = @_;
    my @fields = ('start_date','end_date');
    # test for valid dates
    for my $field (@fields){
        my $date = Utils::validate_date Utils::trim $self->param($field);
        if( $date ){
            $data->{$field} = $date;
        } else {
            $data->{error} = 1;
            $self->stash(($field . '_class') => 'error');
        }
    }
    # test for start_date < end_date
    if( !exists($data->{error}) ){
        my( $start_date, $end_date ) = ( Utils::validate_date($data->{start_date}), 
                                         Utils::validate_date($data->{end_date}) );
        if( $end_date le $start_date ){
            $data->{error} = 1;
            $self->stash( start_date_class => 'error' );
            $self->stash( end_date_class => 'error' );
        }
    }
};

sub page {
    my $self = shift;
    return if !isValidUser($self);
    my $isPost  = ($self->req->method =~ /POST/);

    if( $isPost && (my $data = validate($self)) ){
        if( !exists($data->{error}) ){
            my ($start_date,$end_date) = ($data->{start_date},$data->{end_date});
            warn "Start: $start_date, End: $end_date";
            my $data = Utils::Documents::get_tbalance_data($self,$start_date,$end_date);
            $self->stash( tbalance_data => $data );
        }
    }
}



1;

};
