package AnyEvent::Ident::Request;

use strict;
use warnings;
use v5.10;
use Carp qw( croak );

# ABSTRACT: Simple asynchromous ident response
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

=head2 $res-E<gt>as_string

The raw request as given by the client.

=head2 $res-E<gt>server_port

The server port.

=head2 $res-E<gt>client_port

The client port.

=cut

sub server_port { shift->{server_port} }
sub client_port { shift->{client_port} }
sub as_string { shift->{raw} }

1;
