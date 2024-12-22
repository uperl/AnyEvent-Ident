# AnyEvent::Ident ![linux](https://github.com/uperl/AnyEvent-Ident/workflows/linux/badge.svg) ![windows](https://github.com/uperl/AnyEvent-Ident/workflows/windows/badge.svg) ![macos](https://github.com/uperl/AnyEvent-Ident/workflows/macos/badge.svg) ![msys2-mingw](https://github.com/uperl/AnyEvent-Ident/workflows/msys2-mingw/badge.svg)

Simple asynchronous ident client and server

# SYNOPSIS

client:

```perl
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
```

server:

```perl
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
```

# DESCRIPTION

This module provides a simple procedural interface to [AnyEvent::Ident::Client](https://metacpan.org/pod/AnyEvent::Ident::Client) and
[AnyEvent::Ident::Server](https://metacpan.org/pod/AnyEvent::Ident::Server).

# FUNCTIONS

## ident\_server

```perl
my $server = ident_server $hostname, $port, $callback;
my $server = ident_server $hostname, $port, $callback, \%opt;
```

Start an ident server listening to the address given by `$hostname`
on port `$port`.  For each request `$callback` will be called and
passed in an instance of [AnyEvent::Ident::Transaction](https://metacpan.org/pod/AnyEvent::Ident::Transaction).

`%opt` is optional hash of arguments.  See [AnyEvent::Ident::Server#CONSTRUCTOR](https://metacpan.org/pod/AnyEvent::Ident::Server#CONSTRUCTOR)
for legal key/value pairs and defaults.

## ident\_client

```perl
my $client = ident_client $hostname, $port, $server_port, $client_port, $callback;
```

Make an ident request with the ident server at `$hostname` on port `$port`
with the given port pair `$server_port,$client_port`.  When the response
comes back call `$callback`, with an instance of [AnyEvent::Ident::Response](https://metacpan.org/pod/AnyEvent::Ident::Response).

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

```
# iptables -t nat -A PREROUTING -p tcp --dport 113 -j REDIRECT --to-port 8113
# iptables -t nat -I OUTPUT -p tcp -d 127.0.0.1 --dport 113 -j REDIRECT --to-port 8113
```

The first rule is sufficient for external clients, the second rule was required
for clients connecting via the loopback interface (localhost).

# SEE ALSO

- [AnyEvent::Ident::Client](https://metacpan.org/pod/AnyEvent::Ident::Client)

    Client OO Interface

- [AnyEvent::Ident::Server](https://metacpan.org/pod/AnyEvent::Ident::Server)

    Server OO Interface

- [Net::Ident](https://metacpan.org/pod/Net::Ident)

    Blocking implementation of client only.

- [RFC1413](http://tools.ietf.org/html/rfc1413)

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2013-2024 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
