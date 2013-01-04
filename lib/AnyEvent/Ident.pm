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

=head1 SEE ALSO

L<RFC1413|http://tools.ietf.org/html/rfc1413>,
L<AnyEvent::Ident::Client>,
L<AnyEvent::Ident::Server>

=cut

1;
