#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use Plack::Handler::FCGI;
use EPPlication::Web;
use EPPlication::Util::Config;

my $config      = EPPlication::Util::Config->get;
my $fcgi_socket = $config->{FCGI}{socket};

my $server = Plack::Handler::FCGI->new(
    nproc  => 1,
    listen => [$fcgi_socket],
    detach => 0,
);
$server->run( EPPlication::Web->psgi_app() );
