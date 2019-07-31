package EPPlication::TestKit;

use strict;
use warnings;
use Dir::Self;
use lib __DIR__ . "/../lib";
use Import::Into;
use EPPlication::Util;
use Test::More;
use Test::Warnings;
use Test::Fatal;
use utf8;

BEGIN {
    # load testing config files
    $ENV{ CATALYST_CONFIG_LOCAL_SUFFIX } = 'testing';
}

sub import {
    EPPlication::Util->import::into(1);
    Test::More->import::into(1);
    Test::Warnings->import::into(1, qw/ :all /);
    Test::Fatal->import::into(1, qw/ exception /);
    strict->import::into(1);
    warnings->import::into(1);
    utf8->import::into(1);
}

1;
