package Buh1::Operations; {

=encoding utf8

=head1 NAME

    Operations controller

=cut

use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;

my $OBJECT_NAME = 'business transaction';

sub list{
    my $self = shift;
    return if !$self->is_editor;
    $self->stash(path => '');
    my $controller = $self->stash('controller');
};

sub validate{
    my $self = shift;
    my $edit_mode = shift;
    my $data = { 
        object_name => $OBJECT_NAME,
        updater => Utils::User::current($self) };
    my @fields4rule1 = ('rus','credit','debet');
    for my $field (@fields4rule1){
        $data->{$field} = Utils::trim $self->param($field);
        if ( !$data->{$field} ){
            $data->{error} = 1; 
            $self->stash(($field . '_class') => 'error');
        }
    }
    my @fields4rule2 = ('credit','debet');
    for my $field (@fields4rule2){
        if( $data->{$field} !~ /^\d+[\d+|\d+,|\d+-]+$/ ){
            $data->{error} = 1;
            $self->stash(($field . '_class') => 'error');
        }
    }
    my @optional_fields = ('eng','uzb');
    for my $field (@optional_fields){
        $data->{$field} = Utils::trim $self->param($field) 
            if Utils::trim $self->param($field);
    }
    return($data);
};

sub add{
    my $self = shift;
    return if !$self->is_admin;
    my $controller = $self->stash('controller');

    my $method = $self->req->method;
    my ($data,$id);
    if ( $method =~ /POST/ ){
        $data = validate( $self );
        if( !exists($data->{error}) ){
            if( $id = Db::insert($data) ){
                $self->stash(success => 1);
            } else {
               $self->stash(error => 1);
               warn "$controller:edit:ERROR: could not update!";
            }
        } else {
            $self->stash(error => 1);
        }
    } 
    if( $id ){
        $data = Db::get_objects({id=>[$id]});
        for my $key (keys %{$data->{$id}} ){
            $self->stash($key => $data->{$id}->{$key});
        }
    }
};

# END OF PACKAGE

};

1;

__END__

=head1 AUTHOR

    M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
