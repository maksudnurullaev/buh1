package Utils; {

=encoding utf8

=head1 NAME

    Different utilites 

=cut

use 5.012000;
use strict;
use warnings;
use utf8;
use Cwd;
use Time::Piece;
use Data::UUID;
use File::Spec;
use File::Path qw(make_path);
use DbClient;

sub trim{
    my $string = $_[0];
    if(defined($string) && $string){
        $string =~ s/^\s+|\s+$//g;
        return($string);
    }
    return(undef);
};

sub get_uuid{
    my $ug = new Data::UUID;
    my $uuid = $ug->create;
    my @result = split('-',$ug->to_string($uuid));
    return($result[0]);
};

sub get_date_uuid{
    my $result= Time::Piece->new->strftime('%Y.%m.%d %T ');
    return($result . get_uuid());
};

sub get_root_path{
    my $path = shift;
    if($path){
        my $file = shift;
        if($file){
            return(File::Spec->catfile((cwd(), $path), $file));
        } else {
            return(File::Spec->catdir(cwd(), $path));
        }
    } else {
        return(cwd());
    }
};

sub if_defined{
    my ($self,$key) = @_;
    return(undef) if !defined($self->stash($key));
    return(scalar(@{$self->stash($key)})) if ref($self->stash($key)) eq "ARRAY";
    return(scalar(keys(%{$self->stash($key)}))) if ref($self->stash($key)) eq "HASH"; 
    return($self->stash($key));
};

sub check_for{
    my ($self,$key) = @_;
    return if !defined($key);
    if( $key =~ /^user$/i ){
        return Utils::User::current($self);
    } elsif ( $key =~ /^admin/i) {
        return Utils::User::is_admin($self);
    } elsif ( $key =~ /^mobile$/i ) { 
        return isMobileBrowser($self);
    } elsif ( $key =~ /^company\sname$/g ){
        return $self->session->{'company name'};
    }
    return ;
};

sub isMobileBrowser {
        # http://www.davekb.com/browse_programming_tips:detect_mobile_browser_in_perl:txt
        # http://detectmobilebrowser.com/mobile
        my $self = shift;
        my $user_agent = $self->req->headers->user_agent();
        if( $user_agent ) {
            return 1 if ($user_agent =~ m/android|avantgo|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|symbian|treo|up\.(browser|link)|vodafone|wap|windows (ce|phone)|xda|xiino/i);
            return 1 if (substr($user_agent, 0, 4) =~ m/1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|e\-|e\/|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(di|rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|xda(\-|2|g)|yas\-|your|zeto|zte\-/i);
        }
        return 0;
};

sub is_admin{
    my $self = shift;
    return 1 if Utils::User::is_admin($self);
    $self->redirect_to('/user/login');
    return;
};

sub is_user{
    my $self = shift;
    return 1 if Utils::User::current($self);
    $self->redirect_to('/user/login');
    return;
};

sub is_editor{
    my $self = shift;
    return 1 if Utils::User::is_editor($self);
    return;
};

sub validate_passwords{
    my ($password1, $password2) = @_;
    return(     $password1 
            &&  $password2 
            && ($password1 eq $password2) );
};

sub validate_email{
    my $email = shift;
    return($email =~ /^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$/) if $email;
    return;
};

sub get_paginator{
    my ($self,$prefix,$items_count) = @_;
    my $page = $self->session->{"$prefix/filter/page"} || 1;
    my $pagesize = $self->session->{"$prefix/filter/pagesize"} || 2;
    my $pages;

    if( $pagesize >= $items_count){
        $pages = 1;
        $page = 1;
        $self->session->{"$prefix/filter/page"} = 1;
    }else {
        $pages = $items_count % $pagesize; # tempo 
        $pages = $pages ?
            (($items_count - $pages)/$pagesize) + 1
            : $items_count/$pagesize ;
        if( $pages < $page ){
            $page = $pages;
            $self->session->{"$prefix/filter/page"} = $page;
        }
    }
    return([$page,$pages,$pagesize]);
};

sub get_db_client{
    my $self = shift;
    if ( $self && $self->session('company id') ){
        return(new DbClient($self->session('company id')) );
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
