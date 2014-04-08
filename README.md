# AnyEvent::Ident [![Build Status](https://secure.travis-ci.org/plicease/AnyEvent-Ident.png)](http://travis-ci.org/plicease/AnyEvent-Ident)

Simple asynchronous ident client and server

# SYNOPSIS

client:

    use AnyEvent::Ident qw( ident_client );
    
    ident_client '127.0.0.1', 113, $server_port, $client_port, sub {
      my($res) = @_; # isa AnyEvent::Client::Response 
      if($res->is_success)
      {
        print "user: ", $res->username, "\n"
        print "os:   ", $res->os, "\n"
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

# DESCRIPTION

This module provides a simple procedural interface to [AnyEvent::Ident::Client](https://metacpan.org/pod/AnyEvent::Ident::Client) and
[AnyEvent::Ident::Server](https://metacpan.org/pod/AnyEvent::Ident::Server).

# FUNCTIONS

## ident\_server $hostname, $port, $callback

Start an ident server listening to the address given by `$hostname`
on port `$port`.  For each request `$callback` will be called and
passed in an instance of [AnyEvent::Ident::Transaction](https://metacpan.org/pod/AnyEvent::Ident::Transaction).

## ident\_client $hostname, $port, $server\_port, $client\_port, $callback

Make an ident request with the ident server at `$hostname` on port `$port`
with the given port pair `$server_port,$client_port`.  When the response
comes back call `$callback`, with an instance of [AnyEvent::Ident::Response](https://metacpan.org/pod/AnyEvent::Ident::Response).

# WHY

Why use this distribution instead of [Net::Ident](https://metacpan.org/pod/Net::Ident)?

- Works under Windows (MSWin32)

    [Net::Ident](https://metacpan.org/pod/Net::Ident) installs (even passing its tests) on Windows, but it does not work.
    It may not work in some UNIX environments depending on your headers and libraries.

- Works with [AnyEvent](https://metacpan.org/pod/AnyEvent)

    This distribution will work with any event loop supported by [AnyEvent](https://metacpan.org/pod/AnyEvent).

- Server Included

    This distribution comes with a server, which is handy for testing (take a
    peek at the test suite for [Mojolicious::Plugin::Ident](https://metacpan.org/pod/Mojolicious::Plugin::Ident) to see what I mean.

Sometimes [Net::Ident](https://metacpan.org/pod/Net::Ident) might be more appropriate.  [Net::Ident](https://metacpan.org/pod/Net::Ident) has only
core dependencies and will work on older Perls.  This module requires
[AnyEvent](https://metacpan.org/pod/AnyEvent).  [Net::Ident](https://metacpan.org/pod/Net::Ident) may be easier to wrap
your head around if you don't need or want to run under an event loop.

# CAVEATS

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

Under Linux you can use `iptables` to forward requests from port 113 to
an unprivileged port.  I was able to use this incantation to forward port 113
to port 8113:

    # iptables -t nat -A PREROUTING -p tcp --dport 113 -j REDIRECT --to-port 8113
    # iptables -t nat -I OUTPUT -p tcp -d 127.0.0.1 --dport 113 -j REDIRECT --to-port 8113

The first rule is sufficient for external clients, the second rule was required
for clients connecting via the loopback interface (localhost).

# SEE ALSO

[RFC1413](http://tools.ietf.org/html/rfc1413),
[AnyEvent::Ident::Client](https://metacpan.org/pod/AnyEvent::Ident::Client),
[AnyEvent::Ident::Server](https://metacpan.org/pod/AnyEvent::Ident::Server)

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
