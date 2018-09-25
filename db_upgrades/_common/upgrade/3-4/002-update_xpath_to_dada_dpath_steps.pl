#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

# schema upgrade v3-v4 replaces XPath with Data::DPath
# this script renames steps VarXPath* to VarQueryPath*
# correcting the path has to be done manually.

use
    DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator::ScriptHelpers
    'schema_from_schema_loader';

schema_from_schema_loader(
    { naming => { ALL => 'v8', force_ascii => 1 } },
    sub {
        my ( $schema, $versions ) = @_;

        my $steps_rs = $schema->resultset('Step');
        while ( my $step = $steps_rs->next ) {
            if ($step->type =~ m/^VarXPath(EPP|SOAP|REST)$/xms) {
                my $protocol = $1;
                my $new_type = 'VarQueryPath' . $protocol;
                say "Updating step " . $step->id
                    . "\n\t old: " . $step->type
                    . "\n\t new: $new_type";
                $step->update({ type => $new_type });
            }
        }
    }
);
