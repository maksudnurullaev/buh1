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
    my $file_name = $mojo->session('company id') . '.db';
    my $file_path = $mojo->app->home->rel_file("db/clients/$file_name");
    my $self = { mojo => $mojo, 
                 file => $file_path };
    bless $self, $class;
    return($self);
};

};

1;

__END__

=head1 AUTHOR

 M.Nurullaev <maksud.nurullaev@gmail.com>

=cut

