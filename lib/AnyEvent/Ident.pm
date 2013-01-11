package AnyEvent::Ident;

use strict;
use warnings;
use v5.10;
use base qw( Exporter );

our @EXPORT_OK = qw( ident_server ident_client );

# ABSTRACT: Simple asynchronous ident client and server
# VERSION

=head1 SYNOPSIS

client:

 use AnyEvent::Ident qw( ident_client );
 
 ident_client '127.0.0.1', 113, $server_port, $client_port, sub {
   my($res) = @_; # isa AnyEvent::Client::Response 
   if($res->is_success)
   {
     say "user: ", $res->username;
     say "os:   ", $res->os;
   }
   else
   {
     warn "Ident error: " $res->error_type;
   }
 };

server:

 use AnyEvent::Ident qw( ident_server );
 
 ident_server '127.0.0.1', 113, sub {
   my $tx = shift;
   if($tx->req->server_port == 400
   && $tx->req->client_port == 500)
   {
     $tx->reply_with_user('UNIX', 'grimlock');
   }
   else
   {
     $tx->reply_with_error('NO-USER');
   }
 };

=head1 DESCRIPTION

This module provides a simple procedural interface to L<AnyEvent::Ident::Client> and
L<AnyEvent::Ident::Server>.

=head1 FUNCTIONS

=head2 ident_server $hostname, $port, $callback

Start an ident server listening to the address given by C<$hostname>
on port C<$port>.  For each request C<$callback> will be called and
passed in an instance of L<AnyEvent::Ident::Transaction>.

=cut

sub ident_server
{
  my $hostname = shift;
  my $port     = shift;
  require AnyEvent::Ident::Server;
  my $server = AnyEvent::Ident::Server
    ->new( hostname => $hostname, port => $port )
    ->start(@_);
  # keep the server object in scope so that
  # we don't unbind from the port.  If you 
  # don't want this, then use the OO interface
  # for ::Server instead.
  state $keep = [];
  push @$keep, $server;
  return $server;
}

=head2 ident_client $hostname, $port, $server_port, $client_port, $callback

Make an ident request with the ident server at C<$hostname> on port C<$port>
with the given port pair C<$server_port,$client_port>.  When the response
comes back call C<$callback>, with an instance of L<AnyEvent::Ident::Response>.

=cut

sub ident_client
{
  my $hostname = shift;
  my $port     = shift;
  require AnyEvent::Ident::Client;
  AnyEvent::Ident::Client
    ->new( hostname => $hostname, port => $port )
    ->ident(@_);
}

=head1 WHY

Why use this distribution instead of L<Net::Ident>?

=over 4

=item *

Works under Windows (MSWin32)

L<Net::Ident> installs (even passing its tests) on Windows, but it does not work.
It may not work in some UNIX environments depending on your headers and libraries.

=item *

Works with L<AnyEvent>

This distribution will work with any event loop supported by L<AnyEvent>.

=item *

Server Included

This distribution comes with a server, which is handy for testing (take a
peek at the test suite for L<Mojolicious::Plugin::Ident> to see what I mean.

=back

=head1 CAVEATS

ident is an oldish protocol and almost nobody uses it anymore.  The RFC for the
protocol clearly states that ident should not be used for authentication, at most
it should be used only for audit (for example annotation of log files).  In Windows 
and possibly other operating systems, an unprivileged user can listen to port 113
and on any untrusted network, a remote ident server is not a secure authentication 
mechanism.

No modern operating systems enable the ident service by default, so you can't expect
it to be there unless you have control of the server and have specifically enabled
it.

Most of the time a client wanting to use the ident protocol expects to find 
ident listening to port 113, which on many platforms (such as UNIX) requires
special privileges (such as root).

Under Linux you can use C<iptables> to forward requests to port 113 to
an unprivileged port.  I was able to use this incantation to forward port 113
to port 8113:

 # iptables -t nat -A PREROUTING -p tcp --dport 113 -j REDIRECT --to-port 8113
 # iptables -t nat -I OUTPUT -p tcp -d 127.0.0.1 --dport 113 -j REDIRECT --to-port 8113

The first rule is sufficient for external clients, the second rule was required
for clients connecting via the loopback interface (localhost).

=head1 SEE ALSO

L<RFC1413|http://tools.ietf.org/html/rfc1413>,
L<AnyEvent::Ident::Client>,
L<AnyEvent::Ident::Server>

=cut

1;
