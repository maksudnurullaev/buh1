package Buh1::Guides; {

=encoding utf8

=head1 NAME

    Accounts controller

=cut

use Mojo::Base 'Mojolicious::Controller';
use Utils::Guides ;
use Utils::Files ;
use Utils ;
use Encode qw( encode decode_utf8 );
use Data::Dumper ;
use Text::CSV_XS qw( csv );

sub page{
    my $self = shift;
    $self->stash( guides => Utils::Guides::get_list($self) ) ;
};

sub is_editor{
    my $self = shift ;
    if( !$self->is_admin ){
        $self->redirect_to('/guides/page');
        return(0);
    }
    return(1);
};

sub add{
    my $self = shift ;
    return if !is_editor($self);

    if ( $self->req->method =~ /POST/ ){
        if( Utils::Guides::add_file($self) ){
            $self->stash(success => 1);
            $self->redirect_to('/guides/page');
        } else {
            $self->stash(error => 1);
        }
	}
};

sub edit{
    my $self = shift;
    return if !is_editor($self);

    my $csv_file_path = Utils::Guides::get_guides_path($self->param('payload'));
    my $csv_data = csv (in => $csv_file_path);
    $self->stash(csv_data => $csv_data);
    $self->stash(csv_file_path => $csv_file_path);
    
};


# END OF PACKAGE

};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
