package Tools::Boxcar;

use strict;
use base qw(Module);
use Module::Use qw(Auto::Utils);
use Auto::Utils;
use Mask;
use Multicast;
# --------------------------------------
use NKF;
use LWP::UserAgent;
use HTTP::Request::Common qw(POST);
# --------------------------------------
sub new {
    my $class = shift;
    my $this = $class->SUPER::new;
    $this->{mail}     = undef;
    $this->{password} = undef;
    $this->{keyword}  = undef;
    $this->{channel}  = undef;
    $this->_init;
    return $this;
}

sub _init {
    my $this = shift;

    $this->{mail}     = $this->config->mail;
    $this->{password} = $this->config->password;

    foreach ($this->config->keyword('all')) {
	s/(,)\s+/$1/g;
	my @keywords = split(/,/);
	foreach my $kw (@keywords) {
	    push @{$this->{keyword}}, $kw;
	}
    }
    foreach ($this->config->channel_keyword('all')) {
	s/(,)\s+/$1/g;
	s/\s+(\|)\s+/$1/g;
	my ($channels, $keywords) = split(/\s+/);
	foreach my $ch (split(/,/, $channels)) {
	    $ch = nkf("-w", $ch);
	    $this->{channel}{$ch} = $keywords;
	}
    }
}

############################################################

sub message_arrived {
    my ($this, $msg, $sender) = @_;
    my @result = ($msg);
    
    if ($msg->command eq 'PRIVMSG') {
	my ($sender_nick) = $msg->prefix =~ /(.+)\!/;
	if (!$sender_nick) {
	    if ($sender->isa('IrcIO::Client')) {
		$sender_nick = $sender->{nick};
	    } else {
		$sender_nick = $sender->{current_nick};
	    }
	}

    	my (undef, undef, undef, $reply_anywhere, $get_full_ch_name)
	    = Auto::Utils::generate_reply_closures($msg, $sender, \@result);
	my $channel = nkf("-w", $msg->param(0));
	my $line    = nkf("-w", $msg->param(1));

	my $flag = 0;
	foreach my $kw (@{$this->{keyword}}) {
	    if ($line =~ /$kw/i) {
		Boxcar($this, $channel, $sender_nick, $line);
		$flag++;
		last;
	    }
	}
	if (! $flag) {
	    foreach my $ch (keys %{$this->{channel}}) {
		if (lc($channel) eq lc($ch) and $line =~ /$this->{channel}{$ch}/i) {
		    Boxcar($this, $channel, $sender_nick, $line);
		    last;
		}
	    }
	}
    }
    @result;
}

sub Boxcar {
    my ($this, $channel, $nick, $message) = @_;

    # omit for TIG typable map
    $message =~ s/\s+\x3.*$//;
    $message =~ s/[\x01-\x1F]//g;

    my %formdata = (
	'notification[from_screen_name]' => "$channel $nick",
	'notification[message]' => $message,
	'notification[from_remote_service_id]' => time,
	);
    my $postURI = "https://boxcar.io/notifications";
    my $req = POST($postURI, [%formdata]);
    $req->authorization_basic($this->{mail}, $this->{password});

    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->request($req);
}

1;
