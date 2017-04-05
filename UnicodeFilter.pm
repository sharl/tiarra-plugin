# -*- coding: utf-8 -*-

package Tools::UnicodeFilter;
use strict;
use warnings;
use base qw(Module);
use Data::Dumper;
use Encode;

sub new {
  my $class = shift;
  my $self = $class->SUPER::new;

  $self;
}

sub message_arrived {
  my ($self, $msg, $sender) = @_;

  if ($sender->isa('IrcIO::Server') && ($msg->command eq 'PRIVMSG' || $msg->command eq 'NOTICE')) {
    my $message = $msg->param(1);
    $message =~ s/\\x\{([0-9a-f]+)\}/Encode::encode('utf-8', eval(qq("\\x{$1}")))/ieg;
    $msg->param(1, $message);
  }
  $msg;
}

1;

=pod
# 発言中の "\x{16進コード}" を問答無用で当該 Unicode の文字に変換します．
# 定義とかないのし．
