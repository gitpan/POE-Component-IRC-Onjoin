# $Revision: 1.12 $
# $Id: Onjoin.pm,v 1.12 2001/01/21 11:13:19 afoxson Exp $

# POE::Component::IRC::Onjoin
# Copyright (c) 2001 Adam J. Foxson. All rights reserved.

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

package POE::Component::IRC::Onjoin;

require 5.005;

use strict;
use vars qw($VERSION @ISA);
use Carp;

use POE::Kernel;
use POE::Session;
use POE::Component::IRC;
use POE::Component::IRC::Onjoin::EventProcessor;

local $^W;

($VERSION) = '$Revision: 1.12 $' =~ /\s+(\d+\.\d+)\s+/;
@ISA       = qw(POE::Component::IRC::Onjoin::EventProcessor);

my %defaults =
(
	-switches     => [],
	-nick         => undef,
	-username     => undef,
	-ircname      => 'POE-Component-IRC-Onjoin-' . $VERSION,
	-exitmsg      => 'bye!',      # default message when bot gets dropped
	-delay        => 5,
	-channel      => undef,
	-servers      => [],
	-port	      => 6667,        # default irc server port to connect to
	-interval     => 30,          # default # of min until send msg to channel
	-message      => undef,
	-debug        => 0,
);

sub new
{
	my $self  = shift;
	my $proto = ref $self || $self;
	my $obj   = bless {@_}, $proto;

	$obj->_process_params();  # validate the parameters we were called with
	return $obj;
}

sub _process_params
{
	my $self = shift;

	# we're going to warn the user if they send us a param that we
	# are unfamiliar with, this generally catches typoes.
	for my $param (keys %{$self})
	{
		carp "Parameter '$param' is invalid."
			if not exists $defaults{$param};
	}

	# take the params we were given and merge them over the defaults.
	for my $param (keys %defaults)
	{   
		$self->{$param} = $defaults{$param}
			if not exists $self->{$param};
	}

	for my $arefs (qw(-switches -servers))
	{
		croak "Parameter '$arefs' must be an array reference."
			if not ref $self->{$arefs} eq 'ARRAY';
	}

	# These will always be defined per the defaults, so we check
	# for truth to see if they're valid. '0' should not be
	# valid for any of these. We're not going to get fancy
	# and mandate a '#' before channel names, or message/nick
	# lengths because the IRC server should handle those.
	for my $strings (qw(-nick -channel -message))
	{
		croak "Parameter '$strings' must be specified."
			if not $self->{$strings};
	}

	# We could get silly here and check valid port ranges,
	# but we're not going to do that. :-)
	for my $numbers (qw(-port -interval -delay))
	{
		croak "Parameter '$numbers' must be integral."
			if $self->{$numbers} !~ /^\d+$/;
	}

	# this allows the user to specify boolean options as switches
	# instead of forcing them to do ugly stuff like: debug => 1
	for my $switch (@{$self->{'-switches'}})
	{
		carp "Switch '$switch' is invalid."
			if not exists $self->{$switch};

		$self->{$switch}++;
	}

	$self->{'-username'} = $self->{'-nick'} unless
		defined $self->{'-username'};

	# Make sure at least one server to connect to is specified.
	croak "It would be helpful to specify at least one server."
		if scalar @{$self->{'-servers'}} < 1;
}

sub _start
{
	my ($kernel, $session) = @_[KERNEL, SESSION];

	$session->option(trace => 1) if $session->option('-debug');
	$kernel->alias_set('onjoin_alias');

	$kernel->post('onjoin', 'register',
		qw
		(
			001 433 disconnected socketerr error 353 join
			_send_delayed_notice _time_click
		));

	$kernel->post('onjoin', 'connect',
	{
		Debug    => $session->option('-debug'),
		Nick     => $session->option('-nick'),
		Server   => $session->option('-servers')->
					[rand @{$session->option('-servers')}],
		Port     => $session->option('-port'),
		Username => $session->option('-username'),
		Ircname  => $session->option('-ircname'),
	});
}

sub _stop
{
	my ($kernel, $session) = @_[KERNEL, SESSION];

	$kernel->post('onjoin', 'quit', $session->option('-exitmsg'));
	$kernel->alias_remove('onjoin_alias');
}

sub _time_click
{
	my ($kernel, $session) = @_[KERNEL, SESSION];

	$kernel->post('onjoin', 'privmsg', $session->option('-channel'),
		$session->option('-message'));

	$kernel->delay_add('_time_click', ($session->option('-interval') * 60));
}

sub engage
{
	my $self = shift;

	POE::Component::IRC->new('onjoin', debug => $self->{'-debug'}) or
		die "Can't instantiate new IRC component!\n";

	my $session = POE::Session->create
	(
		# transform the params passed to us via our constructor to
		# poe session options so the can be accessed in the handlers..
		options        => { map { ref $_ ? $_ : m/(?:.+::)?(.+)$/ } %{$self}},
		package_states =>
		[
			$self =>
			[
				qw
				(
					_start _stop irc_001 irc_disconnected irc_error
					irc_353 irc_join irc_socketerr irc_433
					_send_delayed_notice _time_click
				)
			]
		]
	);


	$poe_kernel->run();
}

1;

__END__

=head1 NAME

POE::Component::IRC::Onjoin - Provides IRC moved message & onjoin services

=head1 SYNOPSIS

use POE::Component::IRC::Onjoin;

my $onjoin  = POE::Component::IRC::Onjoin->new
(
  -nick     => 'OnJoinBot',
  -channel  => '#onjoinbot',
  -servers  => [qw(token.rhizomatic.net binky.rhizomatic.net)],
  -message  => q(Hello! Just as an fyi, we moved to #blah),
);

$onjoin->engage();

=head1 DESCRIPTION

This module implements a class that provides moved message and onjoin services
as an IRC bot. Based on the configuration parameters passed to it via it's
constructor it will connect to a channel on a server and immediately send
everyone on that channel a message privately. It will also send the same
message to the channel itself publically at the specified interval. All users
joining the channel thereafter will also recieve the message. 

An useful example of this would be when a channel moves either to a new
channel or network, you would be able to effectively inform anyone
connecting to the old channel about the new one.

Class methods:

  new (constructor)

  Takes the following arguments:

  PARAMETER  TYPE      DEFAULT  DESCRIPTION

  -switches  optional  n/a      Currently only '-debug', which will spew
                                massive debugging data. 
  -nick      mandatory n/a      The nick you want the bot to be.
  -username  optional  n/a      The ident, ie username the bot will have.
  -ircname   optional  seedesc  The name visible from a /whois bot. This will
                                default to 'POE::Component::IRC::Session'.
  -exitmsg   optional  'bye!'   Message shown when the bot is disconnected.
  -channel   mandatory n/a      The channel you want the bot to connect to.
  -servers   mandatory n/a      The servers you want the bot to connect to.
                                It will choose one in a random fashion.
  -port      optional  6667     The port on the server you want the bot to
                                connect to.
  -interval  optional  30       How often in minutes you want the bot to
                                send the message publically to the channel.
  -message   mandatory n/a      The message you want to be sent to the
                                channel and users.
  -delay     optional  5        Number of seconds to wait between messaging
                                users. If this is set too low you will
                                probably be knocked off per "Excess Flood".

Oject methods:

  engage -- Takes no arguments. Initiates the connection. 

=head1 TODO

- Option to remember who we have messaged so we don't annoy
  people by messaging them multiple times when they join.

  If you have any ideas, suggestions, or comments by all means
  drop me an e-mail. Thank you.  ;)

=head1 AUTHOR

Adam J. Foxson <afoxson@guild.net>

=head1 CREDITS

Thanks to fimmtiu@#perl for assistance with tracking down some
particularly nasty early poe bugs, and to uri@#perl for an
excellent code review.

=head1 SEE ALSO

POE::Component::IRC::Onjoin::EventProcessor(3)
perl(1).

=cut
