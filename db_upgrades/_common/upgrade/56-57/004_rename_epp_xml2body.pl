#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use EPPlication::Util::SchemaUpgradeHelper qw/ get_params set_params rename_param /;

use
  DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator::ScriptHelpers
  'schema_from_schema_loader';

schema_from_schema_loader(
    { naming => { ALL => 'v8', force_ascii => 1 } },
    sub {
        my ( $schema, $versions ) = @_;

        my $step_rs = $schema->resultset('Step')->search( { type => 'EPP' } );
        say "EPP step: rename 'xml' field to 'body'";

        while ( my $step = $step_rs->next ) {
            say "Processing step " . $step->id;
            my $params = get_params($step);
            rename_param($params, 'xml', 'body');
            set_params($step, $params);
        }
    }
);
