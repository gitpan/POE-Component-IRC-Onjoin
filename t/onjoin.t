use Test;
use strict;
use POE::Component::IRC::Onjoin;

BEGIN { plan tests => 13 };

my $onjoin = POE::Component::IRC::Onjoin->new
(
	-switches  => [qw(-debug)],
	-nick      => 'OnJoin' . ($$ % 1000),
	-channel   => '#onjoinbot',
	-servers   => [qw(token.rhizomatic.net binky.rhizomatic.net)],
	-interval  => 5,
	-message   => 'Hello! I\'m a test onjoin bot!',
);

ok(ref $onjoin, 'POE::Component::IRC::Onjoin');
ok(scalar @{$onjoin->{-switches}}, 1);
ok(scalar @{$onjoin->{-servers}}, 2);
ok($onjoin->{-delay}, 5);
ok($onjoin->{-port}, 6667);
ok($onjoin->{-interval}, 5);
ok($onjoin->{-debug}, 1);
ok($onjoin->{-exitmsg}, 'bye!');
ok($onjoin->{-ircname} =~ /POE-Component-IRC-Onjoin-/);
ok($onjoin->{-nick} =~ /OnJoin/);
ok($onjoin->{-username} =~ /OnJoin/);
ok($onjoin->{-channel}, '#onjoinbot');
ok($onjoin->{-message} =~ /Hello/);
