#!/usr/bin/env perl
use Dir::Self;
use lib __DIR__ . "/../lib";
use EPPlication::TestKit;

BEGIN {
    use_ok 'EPPlication::Web::Model::DB';
}

done_testing();
