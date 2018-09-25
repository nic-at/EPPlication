#!/usr/bin/env perl
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use EPPlication::TestKit;

BEGIN {
    use_ok 'EPPlication::Web::Model::DB';
}

done_testing();
