#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use JSON;

use
  DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator::ScriptHelpers
  'schema_from_schema_loader';

schema_from_schema_loader(
    { naming => { ALL => 'v8', force_ascii => 1 } },
    sub {
        my ( $schema, $versions ) = @_;

        my $step_rs;

        $step_rs = $schema->resultset('Step')->search({ type => 'CondSubTest' });
        while ( my $step = $step_rs->next ) {
            say 'Copy and remove condition param ' . $step->id;
            doit($step);
        }
    }
);

sub doit {
    my ($step) = @_;

    # Step CondSubTest becomes a normal SubTest with the
    # condition beeing copied from parameters to the condition
    # column

    my $params_raw = $step->get_column('parameters');
    my $params = from_json($params_raw);

    my $condition = delete $params->{condition};
    say "\t$condition";

    $step->set_column( 'type'       => 'SubTest' );
    $step->set_column( 'condition'  => $condition );
    $step->set_column( 'parameters' => to_json($params) );
    $step->update();
}
