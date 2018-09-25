#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

# schema upgrade v1-v2 removes user ownership of tests.
# order was depending on [ 'user_id', 'position' ]
# this script fixes ordering and makes sure the position
# value is unique

use
    DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator::ScriptHelpers
    'schema_from_schema_loader';

schema_from_schema_loader(
    { naming => { ALL => 'v8', force_ascii => 1 } },
    sub {
        my ( $schema, $versions ) = @_;

        my $users_rs = $schema->resultset('User');
        my $position = 1;
        while ( my $user = $users_rs->next ) {
            my $tests_rs = $user->tests;
            while ( my $test = $tests_rs->next ) {
                $test->update({ position => $position });
                $position++;
            }
        }
    }
);
