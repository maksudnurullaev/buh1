package Buh1::Access; {
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;

# This action will render a template
sub page {
    my $self = shift;
    return if !$self->is_admin;
    my $companies = Db::get_objects({name=>['company'],field=>['name']});
    Db::attach_links($companies,'users','user',['email']);
    $self->stash(companies => $companies);
    $self->render();
}

1;

};
