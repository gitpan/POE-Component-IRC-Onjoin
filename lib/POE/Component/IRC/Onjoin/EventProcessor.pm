# $Revision: 1.7 $
# $Id: EventProcessor.pm,v 1.7 2001/01/21 11:13:21 afoxson Exp $

# POE::Component::IRC::Onjoin
# Copyright (c) 2003 Adam J. Foxson. All rights reserved.

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

($VERSION) = '$Revision: 1.7 $' =~ /\s+(\d+\.\d+)\s+/;

sub new {croak "This helper class is not to be instantiated directly."}

sub _send_delayed_notice
{
	my ($kernel, $session) = @_[KERNEL, SESSION];
	my ($nick)             = $_[ARG0];

	$kernel->post('onjoin', 'notice', $nick, $session->option('-message'));
}

# Upon connection to the IRC server..
sub irc_001
{
	my ($kernel, $session) = @_[KERNEL, SESSION];

	$kernel->post('onjoin', 'mode',    $session->option('-nick'), '+i');
	$kernel->post('onjoin', 'join',    $session->option('-channel'));
	$kernel->post('onjoin', 'privmsg', [$session->option('-channel')],
		$session->option('-message'));

	$kernel->delay_add('_time_click', 
		($session->option('-interval') * 60)) if $session->option('-interval');
}

# Upon getting the list of users on the channel we just joined..
sub irc_353
{
	my ($kernel, $session) = @_[KERNEL, SESSION];
	my ($names)            = $_[ARG1];
	my @names              = split(/\s+/, $names);
	my $interval           = 0;

	shift @names;

	for (@names)
	{
		next if /^#/;

		s/^://;
		s/^[\@+]//;

		next if
		/^${\($session->option('-channel'))}|${\($session->option('-nick'))}$/i;

		$kernel->delay_add('_send_delayed_notice',
			$interval += $session->option('-delay'), $_);
	}
}

sub irc_433
{
	my ($server) = $_[ARG0];
	carp "Nick already taken on $server.";
}

sub irc_disconnected
{
	my ($kernel, $session) = @_[KERNEL, SESSION];
	my ($server)           = $_[ARG0];

	carp "Lost connection to server $server. Retrying!";
	$kernel->delay_add('_start', 1);
}

sub irc_error
{
	my ($kernel, $session) = @_[KERNEL, SESSION];
	my $err                = $_[ARG0];

	carp "Server error occurred! $err. Retrying!";
	$kernel->delay_add('_start', 1);
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

	return if $nick =~ /^${\($session->option('-nick'))}$/i;

	$kernel->alarm_add('_send_delayed_notice',
		time + $session->option('-delay'), $nick);
}

1;
