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
use Cwd;
use File::Spec;
use File::Path qw(make_path);
use base 'Mojolicious::Plugin';

our $VERSION        = 'v0.0.1b';
our $DEFAULT_LANG   = 'rus';
our @DEFAULT_LANGS  = ('eng', 'rus', 'uzb');
our $FILE_NAME      = 'ML.INI';
our $ML_DIR            = File::Spec->catdir(cwd(), "ML");
our $DEFAULT_FORMAT = '<a href="/lang/%s">%s</a>'; 

sub process_string;
sub register {
    my ($self,$app) = @_;
    $app->helper( ml => sub { process_string (@_); } ); 
    $app->helper( mlm => sub { process_block (@_); } ); 
    $app->helper( languages_bar => sub { languages_bar (@_); } ); 
};

sub languages_bar{
    my $self = shift;
    my $format = shift || $DEFAULT_FORMAT;
    my $result;
    my $current_lang = get_current_language($self);
    foreach(@DEFAULT_LANGS){
        if($_ eq $current_lang){
            $result .= ($result ? " $_" : $_ );
        } else {
            $result .= ($result ? " " : "" ) . sprintf($format, $_, $_);
        }
    }
    return (Mojo::ByteStream->new($result));
};

sub get_current_language{
    my $self = shift;
    my $current_lang = $self->session->{'lang'} || $DEFAULT_LANG;
    return($current_lang);
};

sub process_string {
    my $self = shift;
    my $key = shift;
    my $value = get_value($key, get_current_language($self));
    return(Mojo::ByteStream->new($value));
};

sub process_block {
    my ($self, $base_language, $key, $block) = @_ ;
    if( !$base_language || !$key || !$block ){
        return(Mojo::ByteStream->new("<font color=red>ERROR:MLM: Invalid MLM block!</font>"));
    }
    my $value = $block->();
    my $current_language = get_current_language($self);
    my $values = load_from_file();
    if($key ~~ $values && $current_language ~~ $values->{$key}){
        $value = $values->{$key}{$current_language};
    } else {
        if( $base_language eq $current_language ){
            $value = set_value($key, $current_language, $value);
        } else {
            $value = set_value($key, $current_language, "[+$base_language]$value");
        }
    }
    return(Mojo::ByteStream->new($value));
};

sub make_my_dir{
    until( -d $ML_DIR ){
        make_path ( $ML_DIR ) || die "Could not create $ML_DIR directory";
    }
    return(1);
};

sub get_value{
    my ($key, $language) = @_;
    if(!$key || !$language){
        return("<font color=red>ERROR:ML: Invalid ML block!</font>");
    }
    my $value;
    my $values = load_from_file();
    if($key ~~ $values && $language ~~ $values->{$key}){
        $value = $values->{$key}{$language};
    } else {
        $value = set_value($key, $language, "[-]");
    }
    if( $value =~ /^\[-/ ) {
        return( "[-$language]$key" );
    } elsif( $value =~ /^\[+/  ) {
        return( $key );
    }
    return( $value );
};

sub set_value{
    my ($key1, $key2, $value) = @_;
    my $values = load_from_file();
    gentle_add($key1, $key2, $value, $values);
    save_to_file($values);
    return($value);
};

sub gentle_add{
    my ($key1, $key2, $value, $values) = @_;
    if($key1 ~~ $values){
        $values->{$key1}{$key2} = $value;
    } else {
        $values->{$key1} = {$key2 => $value};
    }
    
};

sub get_file_path{
    my $file_name = shift || $FILE_NAME;
    return(File::Spec->catfile($ML_DIR, $file_name));
};

sub save_to_file{
    make_my_dir();
    my $values = shift;
    if(!$values){
        #Nothing to save!
        return("");
    }
    my $file_name = $FILE_NAME;
    my $file_path = get_file_path($file_name);
    my ($f);
    open($f, ">:encoding(UTF-8)", "$file_path") || die("Can't open $file_path to write: $!");
    while(my ($key1, $v) = each %{$values} ){
        while(my ($key2,$value) = each %{$v}){
            print $f "$key1:$key2:$value\n"; 
        }
    }
    close($f);
    return($file_path);
};

sub load_from_file{
    make_my_dir();
    my $values = {};
    my $file_name = shift || $FILE_NAME;
    my $file_path = get_file_path($file_name);
    if( -e $file_path ){
        open(my($f), "<:encoding(UTF-8)", "$file_path") || die("Can't open $file_path to read: $!");
        my ($key1, $key2, $value, $line_order);
        while( <$f> ){
            if(/(^[[:print:]]+):([[:print:]]+):(.*)/){
                if( $key1 && $key2 ){   # insert new prefix-key-value
                    chomp($value);      # remove last newline character
                    gentle_add($key1, $key2, $value, $values);
                }
                ( $key1, $key2, $value, $line_order) = ( $1, $2, $3, 1 );
            } else {                    # concatinate values
                $value .= ( ($line_order++) == 1 ? "\n" : "" ) . $_;  # add newline if necessary
            }
        }
        if($key1 && $key2){            #final assinment
            gentle_add($key1, $key2, $value, $values);
        }
        close($f);
    } else {
        warn("File $file_path not found!");
    }
    return($values);
};
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut

