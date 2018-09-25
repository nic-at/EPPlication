#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use EPPlication::Util::SchemaUpgradeHelper qw/ get_params set_params add_param rename_param delete_param /;

use
  DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator::ScriptHelpers
  'schema_from_schema_loader';

schema_from_schema_loader(
    { naming => { ALL => 'v8', force_ascii => 1 } },
    sub {
        my ( $schema, $versions ) = @_;

        my $step_rs = $schema->resultset('Step')->search( { type => 'REST' } );
        say "Process REST steps";

        while ( my $step = $step_rs->next ) {
            say "step " . $step->id;
            my $params = get_params($step);
            rename_param($params, 'json', 'body');
            add_param( $params, 'path', $params->{path_prefix} . $params->{path} );
            delete_param($params, 'path_prefix');
            set_params($step, $params);
        }
    }
);
