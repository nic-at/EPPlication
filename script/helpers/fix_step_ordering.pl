#!/usr/bin/env perl
use 5.018;
use warnings;

use EPPlication::Util;

my $schema = EPPlication::Util::get_schema;

my $test_rs = $schema->resultset('Test')->search();

$schema->txn_do(
    sub {
        while ( my $test = $test_rs->next ) {
            print $test->id . ": ";
            my $step_rs = $test->steps->default_order->search();
            my $pos = 1;
            while ( my $step = $step_rs->next ) {
                $step->update( { position => $pos++ } );
                print '.';
            }
            print "\n";
        }
    }
);
