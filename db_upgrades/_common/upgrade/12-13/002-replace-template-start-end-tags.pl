#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

# schema upgrade v12-v13
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

        my $steps_rs = $schema->resultset('Step')->search(
            { type => { -in => [qw/
                                    VarCheck
                                    VarCheckRegExp
                                    RESTRequestBase
                                    VarVal
                                    SOAPFrame
                                    EPPFrame
                                    QueryPathData
                                    CountPathData
                                /] } }
        );
        while ( my $step = $steps_rs->next ) {
            my $parameters = $step->parameters;

            if ( $parameters =~ s/%(\S+?)%/\[%$1%\]/xmsg ) {
                say "Updating step with id: " . $step->id;
                say $parameters;
                $step->update( { parameters => $parameters } );
            }
        }
    }
);
