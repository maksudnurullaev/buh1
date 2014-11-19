package Utils::Guides; {

=encoding utf8

=head1 NAME

    Files utilites 

=cut

use 5.012000;
use strict;
use warnings;
use utf8;
use Utils;
use Data::Dumper;

sub get_guides_path{
    my ($self,$id) = @_ ;
    if( $id ){
        return( $self->app->home->rel_dir("db/guides/$id") ) ;
    }
    return( $self->app->home->rel_dir('db/guides') ) ;
};

sub get_list{
    my ($self) = @_ ;
    my $path   = get_guides_path($self);
    if( ! -d $path ){
        system "mkdir -p '$path/'" ;
        return ;
    }
    
    my $dir;
    opendir($dir, $path);
    my $result = {};
    while (my $fileid = readdir($dir)) {
        next if ($fileid =~ m/^\./) || ($fileid =~ /desc$/);
        $result->{ $fileid } = {};
        $result->{ $fileid }{file_name} = get_file_content("$path/$fileid" . '.name') ;
        $result->{ $fileid }{desc} = get_file_content("$path/$fileid" . '.desc') ;
    }
    closedir($dir);
    return($result);
};

sub add_guide{
    my $self = shift;
    $self->stash(error => 0);

    my $guide_number      = $self->param('number');
    my $guide_description = $self->param('description');
    my $guide_content     = $self->param('content');
    my $path              = get_guides_path($self);
    my $path_file         = "$path/$guide_number";

    system "mkdir -p '$path/'" if ! -d $path ;
    if( ( -e $path_file) || ($guide_number !~ /^\d+$/) ){
        $self->stash(error => 1);
        $self->stash(number_class => 'error');
    }

    if( !validate_content($guide_content) ){
        $self->stash(error => 1);
        $self->stash(content_class => 'error');
    }
    # Final 
    if( !$self->stash('error') ){
        # save file name
        set_file_content($path_file, $guide_content) ;
        # save file description
        set_file_content($path_file . '.desc', $guide_description) if $guide_description ;
        return($guide_number);
    }
    return(0);
};

sub validate_content{
    my $guide_content = shift;
    return( $guide_content && ($guide_content =~ m/^[,;]\W/m) );
};

sub update_guide{
    my $self = shift;
    $self->stash(error => 0);

    my $guide_number      = $self->param('number');
    warn "Number: " . $guide_number ;
    my $guide_description = $self->param('description');
    my $guide_content     = $self->param('content');
    my $path              = get_guides_path($self);
    my $path_file         = "$path/$guide_number";

    if( !validate_content($guide_content) ){
        $self->stash(error => 1);
        $self->stash(content_class => 'error');
    }
    # Final 
    if( !$self->stash('error') ){
        # save file name
        set_file_content($path_file, $guide_content) ;
        # save file description
        if( $guide_description ){
            set_file_content($path_file . '.desc', $guide_description);
        } else {
            unlink ($path_file . '.desc') if -e ($path_file . '.desc');
        }
        return($guide_number);
    }
    return(0);
};

sub decode_guide_content{
    my $self = shift;
    my $guide_number = shift;
    return(undef) if ! defined($guide_number) ;
    my $guide_file_path = Utils::Guides::get_guides_path($self, $guide_number);
    my $content = Utils::Guides::get_file_content($guide_file_path) ;
    my @rows = split /^/, $content ;
    return(0) if(scalar(@rows) <= 2);
    my $splitter;
    my $result = {};
    for my $index (0 .. $#rows){
        if(!$index){
            if( $rows[$index] =~ /^(\W)/ ){
                $splitter = $1;
                $result->{splitter} = $splitter;
            } else {
                return(0);
            }
        } elsif($index == 1){
            my $row = $rows[$index]; 
            $row =~ s/[\r\n]+//g;
            if( $row ){
                my @row = split(/$splitter/,$row);
                $result->{header} = [@row] ;
            }
        } else {
            my $row = $rows[$index]; 
            $row =~ s/[\r\n]+//g;
            $result->{data} = {} if !exists $result->{data};
            if( $row ){
                my @row = split(/$splitter/,$row);
                $result->{data}{$index} = [@row] ;
            }
        }
    }
    return $result ;
};

sub deploy_guide{
    my $self         = shift;
    my $guide_number = shift;
    my $guide_file_path = Utils::Guides::get_guides_path($self, $guide_number);
    my $guide_file_desc_path = $guide_file_path . '.desc';
    if( ! -e $guide_file_path ){
        $self->redirect_to('guides/page');
        return(0);
    }

    $self->param( number  => $guide_number ) ;
    my $content = Utils::Guides::get_file_content($guide_file_path) ;
    $self->param( content => $content );
    $self->param( description => 
        Utils::Guides::get_file_content($guide_file_desc_path) );
    return(1);
}

sub set_file_content{
    my($file_path,$content) = @_ ;
    return(undef) if !$file_path || !$content ;
    my $fh;
    if( open($fh, "> :encoding(UTF-8)", $file_path) ){
        warn  "Cannot write to $file_path: $!" if ! (print $fh $content) ;
        warn "Cannot close $file_path: $!" if !close($fh) ;
    } else { warn "Cannot open $file_path: $!" } ;
};

sub get_file_content{
    my $file_path = shift;
    return(undef) if !$file_path ;
    my($fh,$content) = (undef,undef);
    if( -e $file_path ){
        if( open(my $fh, "< :encoding(UTF-8)", $file_path) ){
            $content = do { local $/; <$fh> }; 
            warn "Cannot close $file_path: $!" if !close($fh) ;
        } else { warn "Cannot open $file_path: $!" } ;
        return($content)
    }
    return(undef);
};

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

 M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
