package Buh1::Calculations; {

=encoding utf8

=head1 NAME

    Accounts controller

=cut

use Mojo::Base 'Mojolicious::Controller' ;
use Utils::Calculations ;
use Utils::Db ;

sub add{
    my $self = shift;
    Utils::Calculations::add($self) if $self->req->method =~ /POST/; 
};

#sub test{
#    my $self = shift;
#    Utils::Calculations::test($self); 
#};

sub edit{
    my $self = shift;
    Utils::Calculations::edit($self) if $self->req->method =~ /POST/; 
};

sub delete{
    my $self = shift;
    Utils::Calculations::delete($self) ;
};

sub update_fields{
    my $self = shift;
    Utils::Calculations::update_fields($self) if $self->req->method =~ /POST/; 
};

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
