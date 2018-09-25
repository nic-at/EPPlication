#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

# schema upgrade v1-v2 removes user ownership of tests.
# to avoid confusion of tests automatically tag all tests
# with a new tag named after the owner.

use
    DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator::ScriptHelpers
    'schema_from_schema_loader';

schema_from_schema_loader(
    { naming => { ALL => 'v8', force_ascii => 1 } },
    sub {
        my ( $schema, $versions ) = @_;

        my $users_rs = $schema->resultset('User');
        while ( my $user = $users_rs->next ) {
            my $tagname = $user->name;
            my $tag
                = $schema->resultset('Tag')->create( { name => $tagname, } );
            say "Created tag '$tagname'";
            my $tests_rs = $user->tests;
            while ( my $test = $tests_rs->next ) {
                say "\tAdding tag '$tagname' to test '" . $test->name . "'";
                $schema->resultset('TestTag')->create(
                    {   test_id => $test->id,
                        tag_id  => $tag->id,
                    }
                );
            }
        }
    }
);
