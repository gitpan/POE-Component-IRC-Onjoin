# $Revision: 1.6 $
# $Id: EventProcessor.pm,v 1.6 2001/01/19 22:20:22 afoxson Exp $

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

package POE::Component::IRC::Onjoin::EventProcessor;

require 5.005;

use strict;
use vars qw($VERSION);
use Carp;

use POE::Session;

local $^W;

($VERSION) = '$Revision: 1.6 $' =~ /\s+(\d+\.\d+)\s+/;

sub new {croak "This helper class is not to be instantiated directly."}

# Upon connection to the IRC server..
sub irc_001
{
	my ($kernel, $session) = @_[KERNEL, SESSION];

	$kernel->post('onjoin', 'mode',    $session->option('-nick'), '+i');
	$kernel->post('onjoin', 'join',    $session->option('-channel'));
	$kernel->post('onjoin', 'privmsg', [$session->option('-channel')],
		$session->option('-message'));
}

# Upon getting the list of users on the channel we just joined..
sub irc_353
{
	my ($kernel, $session) = @_[KERNEL, SESSION];
	my ($names)            = $_[ARG1];
	my @names              = split(/\s+/, $names);

	for (@names)
	{
		s/^://;
		s/^[@+]//;

		next if /$session->option('-nick')|$session->option('-channel')/i;

		$kernel->post('onjoin', 'notice', $_, $session->option('-message'));
	}
}

sub irc_433
{
	my ($server) = $_[ARG0];
	carp "Nick already taken on $server.";
}

sub irc_disconnected
{
	my ($server) = $_[ARG0];
	carp "Lost connection to server $server.";
}

sub irc_error
{
	my $err = $_[ARG0];
	carp "Server error occurred! $err";
}

sub irc_socketerr
{
	my $err = $_[ARG0];
	carp "Couldn't connect to server: $err";
}

# Upon joining the channel..
sub irc_join
{
	my ($kernel, $session) = @_[KERNEL, SESSION];
	my $nick               = $_[ARG0];
	$nick                  =~ s/(.+)!.+/$1/;

	return if $nick =~ /$session->option('-nick')/i;

	$kernel->post('onjoin', 'notice', $nick, $session->option('-message'));
}

1;
