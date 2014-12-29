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

use Data::Dumper;

our $VERSION        = 'v0.0.1b';
our $FILE_NAME      = 'ML.INI';
our $DIR_NAME       = 'ML';

my $LAST_MODIFY_TIME ;
my $VALUES = {};

sub process_string {
    my $mojo = shift;
    my $key = shift;
    my $value = get_value($mojo,$key, Utils::Languages::current($mojo));
    return(Mojo::ByteStream->new($value));
};

sub process_block {
    my ($mojo, $base_language, $key, $block) = @_ ;
    if( !$base_language || !$key || !$block ){
        return(Mojo::ByteStream->new("<font color='red'>ERROR:MLM: Invalid MLM block!</font>"));
    }
    my $value = $block->();
    my $current_language = Utils::Languages::current($mojo);
    load_from_file($mojo);
    if( exists($VALUES->{$key}) && exists($VALUES->{$key}{$current_language}) ){
        $value = $VALUES->{$key}{$current_language};
    } else {
        if( $base_language eq $current_language ){
            $value = set_value($mojo, $key, $current_language, $value);
        } else {
            $value = set_value($mojo, $key, $current_language, "[+$base_language]$value");
        }
    }
    return(Mojo::ByteStream->new($value));
};

sub make_my_dir{
    my $mojo = shift;
    my $dir = get_file_dir($mojo);
    until( -d $dir ){
        make_path ( $dir ) || die "Could not create $dir directory";
    }
    return(1);
};

sub get_value{
    my ($mojo, $key, $language) = @_;
    if(!$key || !$language){
        return("<font color=red>ERROR:ML: Invalid ML block!</font>");
    }
    my $value;
    load_from_file($mojo);
    if( exists($VALUES->{$key}) && exists($VALUES->{$key}{$language}) ){
        $value = $VALUES->{$key}{$language};
    } else {
        $value = set_value($mojo, $key, $language, "[-]");
    }
    if( $value =~ /^\[-/ ) {
        return( "[-$language]$key" );
    } elsif( $value =~ /^\[+/  ) {
        return( $key );
    }
    return( $value );
};

sub set_value{
    my ($mojo, $key1, $key2, $value) = @_;
    load_from_file($mojo);
    gentle_add($key1, $key2, $value);
    save_to_file($mojo);
    return($value);
};

sub gentle_add{
    my ($key1, $key2, $value) = @_;
    if( exists $VALUES->{$key1} ){
        $VALUES->{$key1}{$key2} = $value;
    } else {
        $VALUES->{$key1} = {$key2 => $value};
    }
    
};

sub get_file_path{
    return(shift->app->home->rel_file("$DIR_NAME/$FILE_NAME"));
};

sub get_file_dir{
    return(shift->app->home->rel_file($DIR_NAME));
};

sub save_to_file{
    my $mojo = shift;
    make_my_dir($mojo);
    if( !$VALUES ){
        #Nothing to save!
        return("");
    }
    my $file_path = get_file_path($mojo);
    my ($f);
    open($f, ">:encoding(UTF-8)", $file_path) || die("Can't open $file_path to write: $!");
    for my $key1 (sort {lc $a cmp lc $b} keys  %{$VALUES} ){
    # while(my ($key1, $v) = each sort keysO %{$VALUES} ){
        while(my ($key2,$value) = each %{$VALUES->{$key1}}){
            print $f "$key1:$key2:$value\n";
        }
    }
    close($f);
    return($file_path);
};

sub load_from_file{
    my $mojo = shift ;
    make_my_dir($mojo);
    my $file_name = shift || $FILE_NAME;
    my $file_path = get_file_path($mojo);
    my ($f);
    if( -e $file_path ){
        open(my($f), "<:encoding(UTF-8)", $file_path) || die("Can't open $file_path to read: $!");
        my $last_modify_time = (stat( $f ))[9];
        if( !$LAST_MODIFY_TIME ||
            $LAST_MODIFY_TIME != $last_modify_time ){
            $LAST_MODIFY_TIME = $last_modify_time;
            my ($key1, $key2, $value, $line_order);
            while( <$f> ){
                if(/(^[[:print:]]+):([[:print:]]+):(.*)/){
                    if( $key1 && $key2 ){   # insert new prefix-key-value
                        chomp($value);      # remove last newline character
                        gentle_add($key1, $key2, $value);
                    }
                    ( $key1, $key2, $value, $line_order) = ( $1, $2, $3, 1 );
                } else {                    # concatinate values
                    $value .= ( ($line_order++) == 1 ? "\n" : "" ) . $_;  # add newline if necessary
                }
            }
            if($key1 && $key2){            #final assinment
                gentle_add($key1, $key2, $value);
            }
        }    
        close($f);
    }
    return($VALUES);
};

};
1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut

