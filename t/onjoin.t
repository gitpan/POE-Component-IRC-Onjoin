#!/usr/bin/perl -w

use strict;

use POE::Component::IRC::Onjoin;

my $onjoin = POE::Component::IRC::Onjoin->new
(
	-switches  => [qw(-debug)],
	-nick      => 'OnJoin' . ($$ % 1000),
	-channel   => '#onjoinbot',
	-servers   => [qw(token.rhizomatic.net binky.rhizomatic.net)],
	-port      => 6667,
	-interval  => 15,
	-message   => 'Hi! I\'m a test onjoin bot!',
);

$onjoin->engage();
