package Utils::Db::Cleaner;

=encoding utf8

=head1 NAME

    Different utilites 

=cut

use 5.012000;
use strict;
use warnings;

use Utils;
use Data::Dumper;
use Test::Mojo;

use utf8;
use open qw( :std :encoding(UTF-8) );
use Db;

use Utils::Accounts;

sub clean_newlines {
    my $mojo = Test::Mojo->new('Buh1');
    my $db   = Db->new($mojo);
    warn 'Works!' if $db->is_valid;
    my $data = Utils::Accounts::get_all_parts($mojo);
    for my $part_id ( keys %{$data} ) {
        check_eng_rus_uzb( $data->{$part_id}, $db );
        my $sections = Utils::Accounts::get_sections( $mojo, $part_id );
        for my $section_id ( keys %{$sections} ) {
            check_eng_rus_uzb( $sections->{ $section_id, $db } );
            my $accounts = Utils::Accounts::get_accounts( $mojo, $section_id );
            for my $account_id ( keys %{$accounts} ) {
                check_eng_rus_uzb( $accounts->{account_id}, $db );
            }
        }
    }

    # warn Dumper $data;
    return 0;
}

sub check_eng_rus_uzb {
    my $record = shift;
    my $db     = shift;
    return if !defined($record);
    my @langs = qw/uzb rus eng/;
    for my $lang (@langs) {
        if ( $record->{$lang} && $record->{$lang} =~ /\n+/ ) {
            warn "($lang)-> " . $record->{$lang};

            $record->{$lang} =~ s/\n+/\s/;
            warn "(NEW)-> " . $record->{$lang};
            warn "(UPDATE)-> " . $record->{object_name};
            warn "(UPDATE)-> " . $record->{id};
            warn "(NEW)-> " . $record->{$lang};

            # $db->update($record);
            #  warn Dumper $record;
        }
    }
}

clean_newlines();

1;

__END__

=head1 AUTHOR

 M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
