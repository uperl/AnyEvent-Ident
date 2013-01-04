use strict;
use warnings;
use v5.10;
use Test::More tests => 12;
use AnyEvent::Ident qw( ident_server ident_client );

my $server = eval {
  ident_server '127.0.0.1', 0, sub {
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
  }
};

isa_ok $server, 'AnyEvent::Ident::Server';
like $server->bindport, qr/^[123456789]\d*$/, "bind port = " . $server->bindport;

my $w = AnyEvent->timer( after => 5, cb => sub { say STDERR "TIMEOUT"; exit } );

do {
  my $done = AnyEvent->condvar;
  
  my $res;
  
  ident_client '127.0.0.1', $server->bindport, 400, 500, sub {
    $res = shift;
    $done->send;
  };
  
  $done->recv;
  
  isa_ok $res, 'AnyEvent::Ident::Response';
  ok $res->is_success, 'is_success';
  is $res->username, 'grimlock', 'username = grimlock';
  is $res->os, 'UNIX', 'os = UNIX';
};

do {
  my $done = AnyEvent->condvar;
  
  my $res;
  
  ident_client '127.0.0.1', $server->bindport, 1,1, sub {
    $res = shift;
    $done->send;
  };
  
  $done->recv;
  
  isa_ok $res, 'AnyEvent::Ident::Response';
  ok !$res->is_success, '!is_success';
  is $res->error_type, 'NO-USER', 'error_type = NO-USER';
};

do {
  my $done = AnyEvent->condvar;
  
  my $res;
  
  ident_client '127.0.0.1', $server->bindport, -1, -1, sub {
    $res = shift;
    $done->send;
  };
  
  $done->recv;
  
  isa_ok $res, 'AnyEvent::Ident::Response';
  ok !$res->is_success, '!is_success';
  is $res->error_type, 'INVALID-PORT', 'error_type = INVALID-PORT';
};
