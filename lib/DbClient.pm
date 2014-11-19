package DbClient; {

=encoding utf8

=head1 NAME

   Functions to work with client's database

=cut

use 5.012000;
use strict;
use warnings;
use utf8;
use parent 'Db';

sub new {
    my $class = shift;
    my $mojo  = shift;
    my $self = { mojo => $mojo, file => $mojo->session('company id') };
    bless $self, $class;
    return($self);
};

sub get_db_path{
    my $self = shift;
    return $self->{'mojo'}->app->home->rel_file("db/clients/$self->{file}.db");
};

};

1;

__END__

=head1 AUTHOR

 M.Nurullaev <maksud.nurullaev@gmail.com>

=cut

