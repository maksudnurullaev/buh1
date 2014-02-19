package HTMLTags; {

=encoding utf8


=head1 NAME

    ML module used to implement simple but powerful i18n support for
    Mojolicious 

=head1 USAGE

    For single line of text:
        <%= ml 'Some single line text' %>

    For multi-line block of text:
        <%= mlm 'rus', 'About as block' => begin %>
        Some text
        with multiple 
        lines
        <% end %>

=cut

use 5.012000;
use strict;
use warnings;
use utf8;
use base 'Mojolicious::Plugin';
use Utils::User;
use Utils::Languages;

our $VERSION        = 'v0.0.1b';

sub register {
    my ($self,$app) = @_;
    $app->helper( ml => sub { ML::process_string (@_); } ); 
    $app->helper( mlm => sub { ML::process_block (@_); } ); 
    $app->helper( languages_bar => sub { Utils::Languages::bar (@_); } ); 
    $app->helper( check_for => sub { Utils::check_for (@_); } ); 
    $app->helper( is_admin  => sub { Utils::is_admin (@_); } );
    $app->helper( user_role2company => sub { Utils::user_role2company (@_); } );
    $app->helper( is_user   => sub { Utils::is_user (@_); } );
    $app->helper( is_editor => sub { Utils::is_editor (@_); } );
    $app->helper( get_date  => sub { Utils::get_date (@_); } );
    $app->helper( currency_format => sub { Utils::currency_format1 (@_); } );
    $app->helper( get_document_number_last => sub { Utils::Documents::get_document_number_last (@_); } );
    $app->helper( generate_name => sub { Utils::Languages::generate_name (@_); } );
    $app->helper( db_get_objects => sub { Utils::Db::db_get_objects (@_) ; } );
    $app->helper( cdb_get_objects => sub { Utils::Db::cdb_get_objects (@_) ; } );
    $app->helper( shrink_if => sub { Utils::shrink_if (@_) ; } );
    $app->helper( tbalance_row => sub { Utils::Documents::tbalance_row (@_); } );
    $app->helper( files_count => sub { Utils::Files::files_count (@_); } );
    $app->helper( calcs_count => sub { Utils::Calculations::count (@_); } );
    $app->helper( cdb_calculate => sub { Utils::Calculations::cdb_calculate (@_); } );
    $app->helper( db_calculate => sub { Utils::Calculations::db_calculate (@_); } );
};

};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut

