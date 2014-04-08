package AnyEvent::Ident::Response;

use strict;
use warnings;

# ABSTRACT: Simple asynchronous ident response
# VERSION

sub new
{
  my $class = shift;
  if(@_ == 1)
  {
    my $raw = shift;
    $raw =~ s/^\s+//;
    $raw =~ s/\s+$//;
    my ($pair, @list) = split /\s*:\s*/, $raw;
    my($server_port, $client_port) = split /\s*,\s*/, $pair;
    my $self = bless { 
      raw => $raw,
      server_port => $server_port,
      client_port => $client_port
    }, $class;
  
    if($list[0] eq 'USERID')
    {
      shift @list;
      ($self->{os}, $self->{charset}) = split /\s,\s*/, shift @list;
      $self->{username} = shift @list;
      $self->{charset} ||= 'US-ASCII';
    }
    else
    {
      shift @list;
      $self->{error_type} = shift @list;
    }
  
    return $self;
  }
  else
  {
     my $args = ref $_[0] eq 'HASH' ? (\%{$_[0]}) : ({@_});
     my $self = bless {
       server_port => $args->{req}->server_port,
       client_port => $args->{req}->client_port,
       username    => $args->{username},
       os          => $args->{os},
       charset     => $args->{charset},
       error_type  => $args->{error_type},
     }, $class;
     $self->{os} = 'OTHER' unless defined $self->{os};
     if($self->{error_type})
     {
       $self->{raw} = join(':', join(',', $self->{server_port}, $self->{client_port}), 'ERROR', $self->{error_type});
     }
     elsif($self->{charset})
     {
       $self->{raw} = join(':', join(',', $self->{server_port}, $self->{client_port}), 'USERID', join(',', $self->{os}, $self->{charset}), $self->{username});
     }
     else
     {
       $self->{raw} = join(':', join(',', $self->{server_port}, $self->{client_port}), 'USERID', $self->{os}, $self->{username});
     }
     return $self;
  }
}

sub _key
{
  my($self) = @_;
  join ':', $self->{server_port}, $self->{client_port};
}

=head1 ATTRIBUTES

=head2 $res-E<gt>as_string

The raw request as it was returned from the server.

=head2 $res-E<gt>is_success

True if the server returned a user and operating system, false otherwise.

=head2 $res-E<gt>server_port

The server port in the original request.

=head2 $res-E<gt>client_port

The client port in the original request.

=head2 $res-E<gt>username

The username in the response.

=head2 $res-E<gt>os

The operating system in the response.

=head2 $res-E<gt>charset

The encoding for the username.  This will be C<US-ASCII> if it
was not provided by the server.

=head2 $res-E<gt>error_type

The error type returned from the server.  Normally, this is one of

=over 4

=item *

INVALID-PORT

=item *

NO-USER

=item *

HIDDEN-USER

=item *

UNKNOWN-ERROR

=back

=cut

sub as_string { shift->{raw} }
sub is_success { defined shift->{username} }
sub server_port { shift->{server_port} }
sub client_port { shift->{client_port} }
sub username { shift->{username} }
sub os { shift->{os} }
sub charset { shift->{charset} }
sub error_type { shift->{error_type} }

1;
