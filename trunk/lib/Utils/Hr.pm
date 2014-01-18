package Utils::Hr; {

=encoding utf8

=head1 NAME

    Database utilites 

=cut

use 5.012000;
use strict;
use warnings;
use utf8;
use Utils::Db;

my ($HR_DESCRIPTOR_NAME,$HR_PERSON_NAME) = 
   ('hr descriptor',    'hr person') ;

sub add{
    my ($self,$data) = @_ ;

};

sub auth{
    my ($self,$access) = @_;
    if( !defined($self->user_role2company) 
		|| $self->user_role2company !~ /$access/i ){
        #TODO $self->stash( noaccess => 1 );
        $self->redirect_to('user/login');
		return;
    }
    return(1);
};

sub form2data{
    my $self = shift;
    my $data = { 
        object_name => $self->param('oname'),
        creator     => Utils::User::current($self),
    };
	$data->{id} = $self->param('id') if $self->param('id') !~ /new/i ;
    $data->{description} = Utils::trim $self->param('description')
        if Utils::trim $self->param('description');
    return($data)
};

sub validate{
    my ($self,$data) = @_ ;
    if( !exists $data->{description} ){
        $self->stash('description_class' => 'error');
        $self->stash('error' => 1);
        return(0);
    }
    return(1);
};

sub get_all_resources{
    my $self = shift;
    my $db = Utils::Db::get_client_db($self);
    if( !$db ){
        warn "Could not connect to client's db!";
        return(undef);
    }
    return({ id => { name => 'Hello from Moscow!' } });
};

# END OF PACKAGE
};

1;

__END__

=head1 AUTHOR

 M.Nurullaev <maksud.nurullaev@gmail.com>

=cut
