#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

# schema upgrade v7-v8
# if a test name exists already simply add dots to
# the end of the name until it is unique.
# this solution is deemed good enough

use
    DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator::ScriptHelpers
    'schema_from_schema_loader';

schema_from_schema_loader(
    { naming => { ALL => 'v8', force_ascii => 1 } },
    sub {
        my ( $schema, $versions ) = @_;

        my $tests_rs = $schema->resultset('Test');
        my $names    = {};
        while ( my $test = $tests_rs->next ) {
            my $old_name = $test->name;
            my $new_name = get_new_name( $names, $old_name );
            if ($new_name ne $old_name) {
                say "Renaming test '$old_name' to '$new_name'";
                $test->update( { name => $new_name } );
            }
        }
    }
);

sub get_new_name {
    my ( $names, $name ) = @_;
    if (exists $names->{ $name }) {
        my $new_name = $name . '.';
        return get_new_name( $names, $new_name );
    }
    else {
        $names->{ $name } = 1;
        return $name;
    }
}
