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
use Utils::Languages;

our $VERSION        = 'v0.0.1b';
our $FILE_NAME      = 'ML.INI';
our $DIR_NAME    = 'ML';

sub process_string {
    my $self = shift;
    my $key = shift;
    my $value = get_value($key, Utils::Languages::current($self));
    return(Mojo::ByteStream->new($value));
};

sub process_block {
    my ($self, $base_language, $key, $block) = @_ ;
    if( !$base_language || !$key || !$block ){
        return(Mojo::ByteStream->new("<font color='red'>ERROR:MLM: Invalid MLM block!</font>"));
    }
    my $value = $block->();
    my $current_language = Utils::Languages::current($self);
    my $values = load_from_file();
    if( exists($values->{$key}) && exists($values->{$key}{$current_language}) ){
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
    my $dir = Utils::get_root_path($DIR_NAME);
    until( -d $dir ){
        make_path ( $dir ) || die "Could not create $dir directory";
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
    if( exists($values->{$key}) && exists($values->{$key}{$language}) ){
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
    if( exists $values->{$key1} ){
        $values->{$key1}{$key2} = $value;
    } else {
        $values->{$key1} = {$key2 => $value};
    }
    
};

sub save_to_file{
    make_my_dir();
    my $values = shift;
    if(!$values){
        #Nothing to save!
        return("");
    }
    my $file_name = shift || $FILE_NAME;
    my $file_path = Utils::get_root_path($DIR_NAME, $file_name);
    my ($f);
    open($f, ">:encoding(UTF-8)", $file_path) || die("Can't open $file_path to write: $!");
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
    my $file_path = Utils::get_root_path($DIR_NAME, $file_name);
    my ($f);
    if( -e $file_path ){
        open(my($f), "<:encoding(UTF-8)", $file_path) || die("Can't open $file_path to read: $!");
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
    }
    return($values);
};
};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut

