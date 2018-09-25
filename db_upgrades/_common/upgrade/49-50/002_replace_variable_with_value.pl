#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use EPPlication::Util::SchemaUpgradeHelper qw/ get_params set_params /;

use
  DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator::ScriptHelpers
  'schema_from_schema_loader';

schema_from_schema_loader(
    { naming => { ALL => 'v8', force_ascii => 1 } },
    sub {
        my ( $schema, $versions ) = @_;

        my $step_rs;

        $step_rs = $schema->resultset('Step')->search( { type => 'VarCheckRegExp' } );
        while ( my $step = $step_rs->next ) {
            say "Upgrade for step " . $step->id;
            my $params = get_params($step);
            say "Replacing 'value' with 'variable'";
            $params->{value} = '[% ' . delete($params->{variable}) . ' %]';
            set_params( $step, $params );
        }
    }
);
