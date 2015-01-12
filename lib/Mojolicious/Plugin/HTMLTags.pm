package Mojolicious::Plugin::HTMLTags; {

=encoding utf8


=head1 NAME

    Add additional useful html tags for in web page templates

=head1 USAGE

    I.e. we could add such code to define user with admin roles:
        % if( is_admin ){
         %= tag h1 => "WOW - you administrator!" 
        % }

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
    $app->helper( ml  => sub { ML::process_string (@_); } ); 
    $app->helper( mlm => sub { ML::process_block (@_); } ); 

    $app->helper( is_mobile_browser => sub { Utils::is_mobile_browser (@_); } );

    $app->helper( languages_bar => sub { Utils::Languages::bar (@_); } ); 
    $app->helper( check_for     => sub { Utils::check_for (@_); } ); 

    $app->helper( who_global     => sub { Utils::User::who_global(@_); } );
    $app->helper( who_local      => sub { Utils::User::who_local(@_); } );
    $app->helper( who_is_global  => sub { Utils::User::who_is_global(@_); } );
    $app->helper( who_is_local   => sub { Utils::User::who_is_local(@_); } );
    $app->helper( who_is         => sub { Utils::User::who_is(@_); } );

    $app->helper( get_document_number_last => sub { Utils::Documents::get_document_number_last (@_); } );
    $app->helper( generate_name   => sub { Utils::Languages::generate_name (@_); } );
    $app->helper( currency_format => sub { Utils::currency_format1 (@_); } );
    $app->helper( db_get_objects  => sub { Utils::Db::db_get_objects (@_) ; } );
    $app->helper( cdb_get_objects => sub { Utils::Db::cdb_get_objects (@_) ; } );
    $app->helper( shrink_if     => sub { Utils::shrink_if (@_) ; } );
    $app->helper( tbalance_row  => sub { Utils::Documents::tbalance_row (@_); } );
    $app->helper( files_count   => sub { Utils::Files::files_count (@_); } );
    $app->helper( calcs_count   => sub { Utils::Calculations::count (@_); } );
    $app->helper( cdb_calculate => sub { Utils::Calculations::cdb_calculate (@_); } );
    $app->helper( db_calculate  => sub { Utils::Calculations::db_calculate (@_); } );
    $app->helper( get_date      => sub { Utils::get_date (@_); } );
    $app->helper( full_url      => sub { Utils::get_full_url (@_); } );
};

};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut

