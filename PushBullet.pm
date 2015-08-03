package Tools::PushBullet;

use strict;
use base qw(Module);
use Module::Use qw(Auto::Utils);
use Auto::Utils;
use Mask;
use Multicast;
# --------------------------------------
use Encode qw(decode encode);
use WWW::PushBullet;
# --------------------------------------
sub new {
    my $class = shift;
    my $this = $class->SUPER::new;
    $this->{source}   = __PACKAGE__;
    $this->{encoding} = undef;
    $this->{apikey}   = undef;
    $this->{device}   = undef;
    $this->{keyword}  = undef;
    $this->{channel}  = undef;
    $this->_init;
    return $this;
}

sub _init {
    my $this = shift;

    $this->{encoding} = $this->config->encoding || 'UTF-8';
    $this->{apikey}   = $this->config->apikey;
    $this->{device}   = $this->config->device;
    foreach ($this->config->keyword('all')) {
	s/(,)\s+/$1/g;
	my @keywords = split(/,/);
	foreach my $kw (@keywords) {
	    push @{$this->{keyword}}, decode($this->{encoding}, $kw);
	}
    }
    foreach ($this->config->channel_keyword('all')) {
	s/(,)\s+/$1/g;
	s/\s+(\|)\s+/$1/g;
	my ($channels, $keywords) = split(/\s+/);
	foreach my $ch (split(/,/, $channels)) {
	    $ch = decode($this->{encoding}, $ch);
	    $this->{channel}{$ch} = decode($this->{encoding}, $keywords);
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
	my $channel = decode($this->{encoding}, $msg->param(0));
	my $line    = decode($this->{encoding}, $msg->param(1));

	my $flag = 0;
	foreach my $kw (@{$this->{keyword}}) {
	    if ($line =~ /$kw/i) {
		PushBullet($this, $channel, $sender_nick, $line);
		$flag++;
		last;
	    }
	}
	unless ($flag) {
	    foreach my $ch (keys %{$this->{channel}}) {
		if (Mask::match($ch, $channel) and $line =~ /$this->{channel}{$ch}/i) {
		    PushBullet($this, $channel, $sender_nick, $line);
		    last;
		}
	    }
	}
    }
    @result;
}

sub PushBullet {
    my ($this, $channel, $nick, $message) = @_;

    # omit for TIG typable map
    $message =~ s/\s+\x3.*$//;
    $message =~ s/[\x01-\x1F]//g;

    my $title = encode('UTF-8', "$channel $nick");
    my $body = encode('UTF-8', $message);

    my $pb = WWW::PushBullet->new({apikey => $this->{apikey}});
    $pb->push_note(
	{
	    device_iden => $this->{device},
	    title       => $title,
	    body        => $body,
	}
	);
}

1;
