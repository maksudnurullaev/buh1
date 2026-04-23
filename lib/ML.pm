package ML; {

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
use File::Path qw(make_path);
use Utils::Languages;

our $VERSION   = 'v0.0.2';
our $FILE_NAME = 'ML.INI';
our $DIR_NAME  = 'ML';

my $LAST_MODIFY_TIME;
my $VALUES = {};

# Called by the ml() template helper.
# Wraps missing/fallback values in HTML markers when in development mode.
sub process_string {
    my $mojo = shift;
    my $key  = shift;
    my $lang = Utils::Languages::current($mojo);
    my $dev  = $mojo && $mojo->app && $mojo->app->mode eq 'development';
    return Mojo::ByteStream->new( get_value($mojo, $key, $lang, $dev) );
}

# Called by the mlm() template helper.
# Strips the [+lang] fallback prefix from stored values so users always
# see readable text instead of the raw marker.
sub process_block {
    my ($mojo, $base_language, $key, $block) = @_;
    if (!$base_language || !$key || !$block) {
        return Mojo::ByteStream->new(
            '<span class="ml-error">ERROR:MLM: Invalid MLM block!</span>');
    }
    my $value            = $block->();
    my $current_language = Utils::Languages::current($mojo);
    load_from_file($mojo);
    if (exists $VALUES->{$key} && exists $VALUES->{$key}{$current_language}) {
        $value = $VALUES->{$key}{$current_language};
        # Strip [+lang] prefix — content after it is the base-language fallback
        $value =~ s/^\[\+[^\]]+\]//;
    } else {
        if ($base_language eq $current_language) {
            $value = set_value($mojo, $key, $current_language, $value);
        } else {
            $value = set_value($mojo, $key, $current_language, "[+$base_language]$value");
        }
    }
    return Mojo::ByteStream->new($value);
}

sub make_my_dir {
    my $mojo = shift;
    my $dir  = get_file_dir($mojo);
    until (-d $dir) {
        make_path($dir) || die "Could not create $dir directory";
    }
    return 1;
}

# Returns the translated string for $key in $language.
#
# $markup = 1  — wrap missing/fallback text in <span> markers (dev mode).
# $markup = 0  — return plain text suitable for non-HTML contexts.
#
# Fallback chain: if the requested language has no usable translation,
# the first other language that has one is returned instead of a bare key.
sub get_value {
    my ($mojo, $key, $language, $markup) = @_;
    if (!$key || !$language) {
        return $markup
            ? '<span class="ml-error">ERROR: ml() called without key</span>'
            : 'ERROR: ml() called without key';
    }
    load_from_file($mojo);

    # Resolve stored value for the requested language
    my $raw;
    if (exists $VALUES->{$key} && exists $VALUES->{$key}{$language}) {
        $raw = $VALUES->{$key}{$language};
    } else {
        # Auto-register placeholder only in development — avoid disk writes in prod
        my $dev = $markup || ($mojo && $mojo->app && $mojo->app->mode eq 'development');
        $raw = $dev ? set_value($mojo, $key, $language, '[-]') : '[-]';
    }

    # Marker values: try the fallback language chain before giving up
    if ($raw =~ /^\[-/ || $raw =~ /^\[\+/) {
        my @fallbacks = grep { $_ ne $language } @{ Utils::Languages::get() };
        for my $fb (@fallbacks) {
            my $fb_raw = (exists $VALUES->{$key} && exists $VALUES->{$key}{$fb})
                         ? $VALUES->{$key}{$fb} : '';
            next unless $fb_raw && $fb_raw !~ /^\[-/ && $fb_raw !~ /^\[\+/;
            # Found a usable fallback — return it, with a visual hint in dev mode
            return $markup
                ? "<span class=\"ml-fallback\" title=\"[$language-&gt;$fb] $key\">$fb_raw</span>"
                : $fb_raw;
        }
        # No usable translation in any language — show bare key
        return $markup
            ? "<span class=\"ml-missing\" title=\"[-$language] $key\">$key</span>"
            : $key;
    }

    return $raw;
}

sub set_value {
    my ($mojo, $key1, $key2, $value) = @_;
    load_from_file($mojo);
    gentle_add($key1, $key2, $value);
    save_to_file($mojo);
    return $value;
}

sub gentle_add {
    my ($key1, $key2, $value) = @_;
    if (exists $VALUES->{$key1}) {
        $VALUES->{$key1}{$key2} = $value;
    } else {
        $VALUES->{$key1} = { $key2 => $value };
    }
}

sub get_file_path {
    return shift->app->home->rel_file("$DIR_NAME/$FILE_NAME");
}

sub get_file_dir {
    return shift->app->home->rel_file($DIR_NAME);
}

sub save_to_file {
    my $mojo = shift;
    make_my_dir($mojo);
    return '' unless $VALUES;
    my $file_path = get_file_path($mojo);
    open(my $f, '>:encoding(UTF-8)', $file_path)
        || die "Can't open $file_path to write: $!";
    for my $key1 (sort { lc $a cmp lc $b } keys %{$VALUES}) {
        while (my ($key2, $value) = each %{ $VALUES->{$key1} }) {
            print $f "$key1:$key2:$value\n";
        }
    }
    close $f;
    return $file_path;
}

sub load_from_file {
    my $mojo = shift;
    make_my_dir($mojo);
    my $file_path = get_file_path($mojo);
    return $VALUES unless -e $file_path;
    open(my $f, '<:encoding(UTF-8)', $file_path)
        || die "Can't open $file_path to read: $!";
    my $mtime = (stat($f))[9];
    unless ($LAST_MODIFY_TIME && $LAST_MODIFY_TIME == $mtime) {
        $LAST_MODIFY_TIME = $mtime;
        my ($key1, $key2, $value, $line_order);
        while (<$f>) {
            if (/(^[[:print:]]+):([[:print:]]+):(.*)/) {
                if ($key1 && $key2) {
                    chomp $value;
                    gentle_add($key1, $key2, $value);
                }
                ($key1, $key2, $value, $line_order) = ($1, $2, $3, 1);
            } else {
                $value .= (($line_order++) == 1 ? "\n" : '') . $_;
            }
        }
        gentle_add($key1, $key2, $value) if $key1 && $key2;
    }
    close $f;
    return $VALUES;
}

};
1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
