#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use JSON;

# add connection params default values to SOAP steps

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
            say 'Add connect params for SOAPFrame ' . $step->id;
            add_connection_params($step);
        }
    }
);

sub add_connection_params {
    my ($step) = @_;

    my $params_raw = $step->get_column('parameters');
    my $params = from_json($params_raw);

    $params->{host} = '[% soap_host %]';
    $params->{port} = '[% soap_port %]';
    $params->{path} = '[% soap_path %]';

    $step->set_column( 'parameters' => to_json($params) );
    $step->update();
}
