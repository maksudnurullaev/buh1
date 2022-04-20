package Buh1::Initial;
{
    use Mojo::Base 'Mojolicious::Controller';
    use Data::Dumper;

    # This action will render a template
    sub welcome {
        my $self = shift;

        if ( $self->stash->{Controller} ) {
            my $c = $self->stash->{Controller};
            my $a = $self->stash->{Action};
            $self->redirect_to(
                {
                    controller => $c,
                    action     => $a
                }
            );
            return;
        }
        $self->render();
    }

    sub lang {
        my $self = shift;
        my $lang = $self->param('payload');    #choosed language
        $self->session->{'lang'} = $lang;
        $self->redirect_to('/');
    }

    1;

};
