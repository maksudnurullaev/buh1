package Buh1::Tbalance; {
use Mojo::Base 'Mojolicious::Controller';
use Utils::Documents;
use Utils::Excel;
use Data::Dumper;

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
    return if !$self->who_is('local','reader');

    if( my $data = validate($self) ){
        if( !exists($data->{error}) ){
            my ($start_date,$end_date) = ($data->{start_date},$data->{end_date});
            my ($tbalance,$tdata) = Utils::Documents::get_tbalance_data($self,$start_date,$end_date);
            if( $self->param('export') ){
                my ($file_path,$file_name) = Utils::Excel::tbalance_export($self, $tbalance,$tdata) ;
                if($file_path && $file_name){
                    $self->render_file( filepath => $file_path, filename => $file_name );
                }
            }
            $self->stash( tbalance => $tbalance );
            $self->stash( tdata   => $tdata );
        }
    }
};



1;

};
