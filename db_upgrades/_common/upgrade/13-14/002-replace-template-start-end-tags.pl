#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

# schema upgrade v13-v14
# forgot some step types in the previous upgrade
# replace template toolkit START_TAG and END_TAG
# used to be '% some_var_name %' but because of escaping problems we
# go back to using the default '[% some_var_name %]'
use
    DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator::ScriptHelpers
    'schema_from_schema_loader';

schema_from_schema_loader(
    { naming => { ALL => 'v8', force_ascii => 1 } },
    sub {
        my ( $schema, $versions ) = @_;

        my $steps_rs = $schema->resultset('Step');
        while ( my $step = $steps_rs->next ) {
            my $parameters = $step->parameters;

            # regexp replaces all occurrences of %var% unless they are
            # already written as [%var%]
            if ( $parameters =~ s/([^\[%]|^)%([\w\ -]+?)%([^\]%]|$)/$1\[%$2%\]$3/msg ) {
                say "Updating step with id: " . $step->id;
                say $parameters;
                $step->update( { parameters => $parameters } );
            }
        }
    }
);
