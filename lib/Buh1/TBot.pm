package Buh1::TBot; {

use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;

use WWW::Telegram::BotAPI;
my $tBotApi = WWW::Telegram::BotAPI->new (
    token => '6938590791:AAFOQjRSBR1hJ9cTK4nrdY-a4jBl_J-wwtw'
);

sub match_all_positions {
    my ($regex, $string) = @_;
    my @ret;
    while ($string =~ /$regex/mg) {
        my $sPos = $-[0];
        # my $ePos = $+[0];
        push @ret, {
            'length' => 8,
            'offset' => $sPos,
            'url' => ('https://cdp.colvir.ru/TrackStudio/app/task/' . $1),
            'type' => 'text_link'
        };
    }
    # warn "Test #2";
    while ($string =~ /^(.*:)$/mg) {
        my $sPos = $-[0];
        my $ePos = $+[0];
	#warn $1;
        push @ret, {
            'length' => ($ePos - $sPos),
            'offset' => $sPos,
	    'type' => 'bold'
        };
        push @ret, {
            'length' => ($ePos - $sPos),
            'offset' => $sPos,
	    'type' => 'underline'
        };
    }
    return [@ret]
}

sub hello {
    my $self   = shift;
    #warn "PAYLOAD: " . $self->param('payload');
    #warn "METHOD: " . $self->req->method;
    #warn Dumper($self->req->json);
    if($self->req->method eq 'POST' && $self->req->json && $self->req->json->{message} && $self->req->json->{message}{text}){
	#warn "Message from BOT: " . $self->req->json->{message}{text};
        #match_all_positions('#(\d{7})', $self->req->json->{message}{text});
        $tBotApi->sendMessage ({
            chat_id      => $self->req->json->{message}{chat}{id},
            link_preview_options => { is_disabled => \1 }, 
            text => $self->req->json->{message}{text},
            entities => match_all_positions('[#?!](\d{7})', $self->req->json->{message}{text})
        });

    }
    $self->render(text => 'Hello from <strong>telegram bot</strong>: ColvirTextD72Links!');        
}

1;

};
