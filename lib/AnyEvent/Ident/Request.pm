package AnyEvent::Ident::Request;

use strict;
use warnings;
use Carp qw( croak );

# ABSTRACT: Simple asynchronous ident response
# VERSION

sub new
{
  my $class = shift;
  my $self = bless {}, $class;
  if(@_ == 1)
  {
    my $raw = $self->{raw} = shift;
    if($raw =~ /^\s*(\d+)\s*,\s*(\d+)\s*$/)
    {
      croak "invalid port" if $1 == 0    || $2 == 0
      ||                      $1 > 65535 || $2 > 65535;
      ($self->{server_port}, $self->{client_port}) = ($1, $2);
    }
    else
    {
      croak "bad request: $raw";
    }
  }
  elsif(@_ == 2)
  {
    $self->{raw} = join(',', ($self->{server_port}, $self->{client_port}) = @_);
  }
  else
  {
    croak 'usage: AnyEvent::Ident::Request->new( [ $raw | $server_port, $client_port ] )';
  }
  $self;
}

=head1 ATTRIBUTES

=head2 as_string

 my $str = $res->as_string;

The raw request as given by the client.

=head2 server_port

 my $port = $res->server_port;

The server port.

=head2 client_port

 my $port = $res->client_port;

The client port.

=cut

sub server_port { shift->{server_port} }
sub client_port { shift->{client_port} }
sub as_string { shift->{raw} }

1;
