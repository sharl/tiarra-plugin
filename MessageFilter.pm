# -*- coding: utf-8 -*-

package Tools::MessageFilter;
use strict;
use warnings;
use base qw(Module);
use Mask;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new;

    $self->{head} = $self->config->head || '';
    $self->{tail} = $self->config->tail || '';

    $self;
}

sub message_arrived {
    my ($self, $msg, $sender) = @_;

    if ($sender->isa('IrcIO::Server') &&
	($msg->command eq 'PRIVMSG' || $msg->command eq 'NOTICE')) {
	foreach ($self->config->pattern('all')) {
	    if (my ($user, $pattern, $replace) = m/^(.+?)\s+(.+)\s+(.+)$/o) {
		if (Mask::match($user, $msg->prefix)) {
		    my $message = $msg->param(1);
		    $message =~ s/$pattern/$self->{head}$replace$self->{tail}/g;
		    $msg->param(1, $message);
		    last;
		}
	    }
	}
    }
    $msg;
}

1;

=pod
# 人物のマスクと、パターン、置換パターンを定義。
# パターンを置換パターンに変換
# 人物が複数のマスクに一致する場合は、最初に一致したものが使われます。
pattern: *!*@* pattern replace

# hogehoge を ほげほげ に変換します
pattern: *!*@* hogehoge ほげほげ

# 置換パターンの前後につける文字列
head: [
tail: ]
=cut
