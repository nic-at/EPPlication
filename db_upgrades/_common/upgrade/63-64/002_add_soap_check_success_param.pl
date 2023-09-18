#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use JSON;

# add check_success param to SOAP steps

use
  DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator::ScriptHelpers
  'schema_from_schema_loader';

schema_from_schema_loader(
    { naming => { ALL => 'v8', force_ascii => 1 } },
    sub {
        my ( $schema, $versions ) = @_;

        my $step_rs;

        $step_rs = $schema->resultset('Step')->search({ type => 'SOAP' });
        while ( my $step = $step_rs->next ) {
            say 'Add default check_success param to SOAP step ' . $step->id;
            add_param($step);
        }
    }
);

sub add_param {
    my ($step) = @_;

    my $params_raw = $step->get_column('parameters');
    my $params = from_json($params_raw);

    $params->{check_success} = 1;

    $step->set_column( 'parameters' => to_json($params) );
    $step->update();
}
