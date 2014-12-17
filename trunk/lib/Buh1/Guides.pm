package Buh1::Guides; {

=encoding utf8

=head1 NAME

    Accounts controller

=cut

use Mojo::Base 'Mojolicious::Controller';
use Utils::Files ;
use Utils ;
use Utils::Guides;
use Encode qw( encode decode_utf8 );
use Data::Dumper ;
use Text::CSV_XS qw( csv );

sub page{
    my $self = shift;
    $self->stash( guides => Utils::Guides::get_list($self) ) ;
};

sub add{
    my $self = shift ;

    if ( $self->req->method =~ /POST/ ){
        if( my $guide_number = Utils::Guides::add_guide($self) ){
            $self->stash(success => 1);
            $self->redirect_to("/guides/edit/$guide_number");
        } else {
            $self->stash(error => 1);
        }
	}
};

sub edit{
    my $self                 = shift;

    my $guide_number        = $self->param('payload');
    if( $self->req->method =~ /POST/ ){
        if( Utils::Guides::update_guide($self) ){
            $self->stash(success => 1);
        } else {
            $self->stash(error => 1);
            return;
        }
	}
    #Final
    Utils::Guides::deploy_guide($self,$guide_number);
};

sub view{
    my $self            = shift;
    my $guide_number    = $self->param('payload');
    $self->stash( guide_data => Utils::Guides::decode_guide_content($self, $guide_number) );
    #Final
    Utils::Guides::deploy_guide($self,$guide_number);
};

sub del{
    my $self = shift ;

    my $guide_number      = $self->param('payload');
    my $path              = Utils::Guides::get_guides_path($self);
    my $path_file         = "$path/$guide_number";
    warn $path_file;
    warn ($path_file . '.desc') if -e ($path_file . '.desc');
    unlink $path_file;
    unlink ($path_file . '.desc') if -e ($path_file . '.desc');
    $self->redirect_to('/guides/page');
};

# END OF PACKAGE

};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
