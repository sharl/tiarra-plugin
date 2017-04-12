# -*- coding: utf-8 -*-

package Tools::UnicodeFilter;
use strict;
use warnings;
use base qw(Module);
use Data::Dumper;
use Encode;
use Text::SlackEmoji;

sub new {
  my $class = shift;
  my $self = $class->SUPER::new;

  $self->{codepoint}   = $self->config->codepoint   || 0;
  $self->{slack_emoji} = $self->config->slack_emoji || 0;

  $self->{slack_emoji_map} = Text::SlackEmoji->emoji_map;

  $self;
}

sub message_arrived {
  my ($self, $msg, $sender) = @_;

  if ($sender->isa('IrcIO::Server') && ($msg->command eq 'PRIVMSG' || $msg->command eq 'NOTICE')) {
    my $message = $msg->param(1);
    if ($self->{codepoint}) {
      $message =~ s/\\x\{([0-9a-f]+)\}/Encode::encode('utf-8', eval(qq("\\x{$1}")))/ieg;
    }
    if ($self->{slack_emoji}) {
      print STDERR $message;
      $message =~ s!:([-+a-z0-9_]+):!Encode::encode('utf-8', $self->{slack_emoji_map}->{$1}) // ":$1:"!ge;
    }
    $msg->param(1, $message);
  }
  $msg;
}

1;

=pod
  # 発言中の "\x{16進コード}" を問答無用で当該 Unicode の文字に変換します．
  codepoint: 1
  # 発言中の ":sushi:" といった Slack で使えるっぽいやつを問答無用で当該 Unicode Emoji に変換します．
  slack-emoji: 1

