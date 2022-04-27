package Buh1::Tbalance;
{
    use Mojo::Base 'Mojolicious::Controller';
    use Utils::Documents;
    use Utils::Excel;
    use Data::Dumper;

    sub page {
        my $self = shift;
        return if !$self->who_is( 'local', 'reader' );

        my ( $start_date, $end_date ) =
          ( $self->param('start_date'), $self->param('end_date') );
        if ( $start_date && $end_date ) {
            my ( $tbalance, $tdata ) =
              Utils::Documents::get_tbalance_data( $self, $start_date,
                $end_date );
            if ( $self->param('export') ) {
                my ( $file_path, $file_name ) =
                  Utils::Excel::tbalance_export( $self, $tbalance, $tdata );
                if ( $file_path && $file_name ) {
                    $self->render_file(
                        filepath => $file_path,
                        filename => $file_name
                    );
                }
            }
            $self->stash( tbalance => $tbalance );
            $self->stash( tdata    => $tdata );
            $self->stash(
                tdates => { start_date => $start_date, end_date => $end_date }
            );
        }
    }

    1;

};
