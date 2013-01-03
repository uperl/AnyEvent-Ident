package AnyEvent::Ident::Client;

use strict;
use warnings;
use v5.10;
use AnyEvent::Socket qw( tcp_connect );
use AnyEvent::Handle;
use Carp qw( carp );
use AnyEvent::Ident::Response;

# ABSTRACT: Simple asynchromous ident client
# VERSION

=head1 SYNOPSIS

 use AnyEvent::Ident::Client;
 
 my $client = AnyEvent::Ident::Client->new;
 $client->ident($server_port, $client_port, sub {
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
 });

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
    hostname => $args->{hostname} // '127.0.0.1',  
    port     => $args->{port}     // 113,
    on_error => $args->{on_error} // sub { carp $_[0] },
  }, $class;
}

=head1 METHODS

=head2 $client-E<gt>ident( $server_port, $client_port, $callback )

Send an ident request to the ident server with the given TCP port pair.
The callback will be called when the response is returned from the
server.  Its only argument will be an instance of 
L<AnyEvent::Ident::Response>.

On the first call to this method, a connection to the ident server
is opened, and will remain open until C<close> (see below) is called,
or if the C<$client> object falls out of scope.

=cut

sub ident
{
  my($self, $server_port, $client_port, $cb) = @_;
  
  my $key = join ':', $server_port, $client_port;
  push @{ $self->{$key} }, $cb;
  return if @{ $self->{$key} } > 1;
  
  # if handle is defined then the connection is open and we can push 
  # the request right away.
  if(defined $self->{handle})
  {
    $self->{handle}->push_write("$server_port,$client_port\015\012");
    return;
  }
  
  # if handle is not defined, but wait is, then we are waiting for
  # the connection, and we queue up the request
  if(defined $self->{wait})
  {
    push @{ $self->{wait} }, "$server_port,$client_port\015\012";
    return;
  }
  
  $self->{wait} = [];
  
  tcp_connect $self->{hostname}, $self->{port}, sub {
    my($fh) = @_;
    return $self->{on_error}->("unable to connect: $!") unless $fh;
    
    $self->{handle} = AnyEvent::Handle->new(
      fh       => $fh,
      on_error => sub {
        my ($hdl, $fatal, $msg) = @_;
        $self->{on_error}->($msg);
        $self->_cleanup;
        $_[0]->destroy;
        delete $self->{handle};
      },
      on_eof   => sub {
        $self->_cleanup;
        $self->{handle}->destroy;
       delete $self->{handle};
      },
    );
    
    $self->{handle}->push_write("$server_port,$client_port\015\012");
    $self->{handle}->push_write($_) for @{ $self->{wait} };
    delete $self->{wait};
    
    $self->{handle}->on_read(sub {
      $self->{handle}->push_read( line => sub {
        my($handle, $line) = @_;
        $line =~ s/\015?\012//g;
        my $res = AnyEvent::Ident::Response->new($line);
        my $key = $res->_key;
        if(defined $self->{$key})
        {
          $_->($res) for @{ $self->{$key} };
          delete $self->{$key};
        }
      });
    });
  };
  
  return $self;
}

=head2 $client-E<gt>close

Close the connection to the ident server.  Requests that are in progress will
receive an error response with the type C<UNKNOWN-ERROR>.

=cut

sub _cleanup
{
  my $self = shift;
  foreach my $key (grep /^(\d+):(\d+)$/, keys %$self)
  {
    $_->(AnyEvent::Ident::Response->new("$1,$2:ERROR:UNKNOWN-ERROR"))
      for @{ $self->{$key} };
  }
}

sub close
{
  my $self = shift;
  if(defined $self->{handle})
  {
    $self->_cleanup;
    $self->{handle}->destroy;
    delete $self->{handle};
    delete $self->{wait};
  }
}

sub DESTROY
{
  shift->close;
}

1;
