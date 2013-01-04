package AnyEvent::Ident::Server;

use strict;
use warnings;
use v5.10;
use AnyEvent;
use AnyEvent::Socket qw( tcp_server );
use AnyEvent::Handle;
use AnyEvent::Ident::Request;
use AnyEvent::Ident::Response;
use AnyEvent::Ident::Transaction;
use Carp qw( croak );

# ABSTRACT: Simple asynchronous ident server
# VERSION

=head1 SYNOPSIS

 use AnyEvent::Ident::Server;
 my $server = AnyEvent::Ident::Server->new;
 
 $server->start(sub {
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
 });

=head1 DESCRIPTION

Provide a simple asynchronous ident server.

=head1 CONSTRUCTOR

The constructor takes the following optional arguments:

=over 4

=item *

hostname (default 127.0.0.1)

The hostname to connect to.

=item *

port (default 113)

The port to connect to.

=item *

on_error (carp error)

A callback subref to be called on error (either connection or transmission error).
Passes the error string as the first argument to the callback.

=back

=cut

sub new
{
  my $class = shift;
  my $args     = ref $_[0] eq 'HASH' ? (\%{$_[0]}) : ({@_});
  bless {
    hostname => $args->{hostname},  
    port     => $args->{port}     // 113,
    on_error => $args->{on_error} // sub { carp $_[0] },
  }, $class;
}

=head2 $server-E<gt>start( $callback )

Start the Ident server.  The given callback will be called on each ident
request (there may be multiple ident requests for each connection).  The
first and only argument passed to the callback is the transaction, an
instance of L<AnyEvent::Ident::Transaction>.  The most important attribute
on the transaction object are C<res>, the response object (itself an instance of 
L<AnyEvent::Ident::Transaction> with C<server_port> and C<client_port>
attributes) and the most important methods on the transaction object are
C<reply_with_user> and C<reply_with_error> which reply with a successful and 
error response respectively.

=cut

sub start
{
  my($self, $callback) = @_;
  
  croak "already started" if $self->{guard};
  
  my $cb = sub {
    my ($fh, $host, $port) = @_;

    my $handle;
    $handle = AnyEvent::Handle->new(
      fh       => $fh,
      on_error => sub {
        my ($hdl, $fatal, $msg) = @_;
        $self->{on_error}->($msg);
        $_[0]->destroy;
      },
      on_eof   => sub {
        $handle->destroy;
      },
    );
    
    $handle->on_read(sub {
      $handle->push_read( line => sub {
        my($handle, $line) = @_;
        $line =~ s/\015?\012//g;
        my $req = eval { AnyEvent::Ident::Request->new($line) };
        return $handle->push_write("$line:ERROR:INVALID-PORT\015\012") if $@;
        my $tx = bless { 
          req            => $req,
          remote_port    => $port,
          local_port     => $self->{bindport},
          remote_address => $host,
          cb             => sub {
            my($res) = @_;
            $handle->push_write($res->as_string . "\015\012");
          },
        }, 'AnyEvent::Ident::Transaction';
        $callback->($tx);
      })
    });
  };
  
  if($self->{port} == 0)
  {
    my $done = AnyEvent->condvar;
    $self->{guard} = tcp_server $self->{hostname}, undef, $cb, sub {
      my($fh, $host, $port) = @_;
      $self->{bindport} = $port;
      $done->send;
    };
    $done->recv;
  }
  else
  {
    $self->{guard} = tcp_server $self->{hostname}, $self->{port}, $cb;
    $self->{bindport} = $self->{port};
  }
  
  $self;
}

=head2 $server-E<gt>bindport

The bind port.  If port is set to zero in the constructor or on
start, then an ephemeral port will be used, and you can get the
port number here.

=cut

sub bindport { shift->{bindport} }

=head2 $server-E<gt>stop

Stop the server and unbind to the port.

=cut

sub stop
{
  my($self) = @_;
  delete $self->{guard};
  delete $self->{bindport};
  $self;
}

1;
