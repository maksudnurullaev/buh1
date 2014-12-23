package Utils::Operations; {

=encoding utf8

=head1 NAME

   Utils

=cut

use 5.012000;
use strict;
use warnings;
use utf8;

my $OBJECT_NAME = 'business transaction';

sub get_object_name{ return($OBJECT_NAME); };

sub validate{
    my $self = shift;
    my $edit_mode = shift;
    my $data = { 
        object_name => $OBJECT_NAME,
        account => $self->param('account'),
        updater => Utils::User::current($self) };
    my @fields4rule1 = ('number','rus','credit','debet');
    for my $field (@fields4rule1){
        $data->{$field} = Utils::trim $self->param($field);
        if ( !$data->{$field} ){
            $data->{error} = 1; 
            $self->stash(($field . '_class') => 'error');
        }
    }
    if( $data->{number} !~ /^[1-9][0-9]*\.?[0-9]*$/ ){
        $data->{error} = 1;
         $self->stash('number_class' => 'error');
    }
    my @fields4rule2 = ('credit','debet');
    for my $field (@fields4rule2){
        if( $data->{$field} !~ /^\d+[\d+|\d+,|\d+-]+$/ ){
            $data->{error} = 1;
            $self->stash(($field . '_class') => 'error');
        }
    }
    my @optional_fields = ('eng','uzb');
    for my $field (@optional_fields){
        $data->{$field} = Utils::trim $self->param($field) 
            if Utils::trim $self->param($field);
    }
    return($data);
};



# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

 M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
