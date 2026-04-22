requires 'Mojolicious';
requires 'Crypt::SaltedHash';
requires 'Data::UUID';
requires 'DBI';
requires 'DBD::SQLite';
requires 'List::MoreUtils';
requires 'Locale::Currency::Format';
requires 'Mojolicious::Plugin::RenderFile';
requires 'Mojolicious::Plugin::AdditionalValidationChecks';
requires 'Hash::Merge::Simple';
requires 'Text::CSV_XS';
requires 'CHI';
requires 'EV';
requires 'Spreadsheet::WriteExcel';
requires 'WWW::Telegram::BotAPI';
requires 'Net::SSLeay';
requires 'IO::Socket::SSL', '2.009';

on test => sub {
    requires 'Test::Most';
    requires 'Test::Deep';
    requires 'Test::NoWarnings';
    requires 'Test::Mojo::Session';
};
