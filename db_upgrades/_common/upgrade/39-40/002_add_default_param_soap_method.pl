#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use JSON;

# soap_method is a step param now, do not read from variable 'soap_method' anymore
# add param "method" for SOAPFrame steps
# rm steps with type 'VarVal' that assign to variable 'soap_method'

use
  DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator::ScriptHelpers
  'schema_from_schema_loader';

schema_from_schema_loader(
    { naming => { ALL => 'v8', force_ascii => 1 } },
    sub {
        my ( $schema, $versions ) = @_;

        my $step_rs;

        $step_rs = $schema->resultset('Step')->search({ type => 'SOAPFrame' });
        while ( my $step = $step_rs->next ) {
            say 'Add SOAP method for step ' . $step->id;
            add_param($step, 'method', 'POST');
        }

        $step_rs = $schema->resultset('Step')->search({ type => 'VarVal' });
        while ( my $step = $step_rs->next ) {
            my $params_raw = $step->get_column('parameters');
            my $params = from_json($params_raw);
            if ($params->{variable} eq 'soap_method') {
                say 'Remove step assigning to "soap_method" (id:' . $step->id . ')';
                $step->delete;
            }
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
