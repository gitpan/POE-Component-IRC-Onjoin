#!/usr/bin/perl -w

use strict;

use POE::Component::IRC::Onjoin;

my $onjoin = POE::Component::IRC::Onjoin->new
(
	-switches  => [qw(-debug)],
	-nick      => 'OnJoin' . ($$ % 1000),
	-channel   => '#onjoinbot',
	-servers   => [qw(token.rhizomatic.net binky.rhizomatic.net)],
	-interval  => 5,
	-message   => 'Hello! I\'m a test onjoin bot!',
);

$onjoin->engage();
