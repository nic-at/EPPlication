#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use JSON;

# Change step type from VarUpperCase to Transformation
# new param: 'transformation' => 'uppercase'
# replace param: variable => var_result
# replace param: value => input

use
  DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator::ScriptHelpers
  'schema_from_schema_loader';

schema_from_schema_loader(
    { naming => { ALL => 'v8', force_ascii => 1 } },
    sub {
        my ( $schema, $versions ) = @_;

        my $step_rs = $schema->resultset('Step')->search({ type => 'VarUpperCase' });
        while ( my $step = $step_rs->next ) {
            say 'Change VarUpperCase step "' . $step->name . '" to Transformation';

            $step->set_column( type => 'Transformation');
            replace_param($step, 'variable', 'var_result');
            replace_param($step, 'value', 'input');
            add_param($step, 'transformation', 'uppercase');

            $step->update();
        }
    }
);

sub add_param {
    my ($step, $key, $value) = @_;

    say $step->type . '(' . $step->id . ") add param $key => $value";
    my $params_raw = $step->get_column('parameters');
    my $params = from_json($params_raw);
    $params->{$key} = $value;
    $step->set_column( 'parameters' => to_json($params) );
    $step->update();
}
sub replace_param {
    my ($step, $old, $new) = @_;

    say $step->type . '(' . $step->id . ") replace param $old => $new";
    my $params_raw = $step->get_column('parameters');
    my $params = from_json($params_raw);
    $params->{$new} = delete $params->{$old};
    $step->set_column( 'parameters' => to_json($params) );
    $step->update();
}
