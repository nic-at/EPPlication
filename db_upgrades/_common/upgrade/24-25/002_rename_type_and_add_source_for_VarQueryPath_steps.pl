#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

# schema upgrade v24-v25
# change type from VarQueryPath[EPP|SOAP|REST] to VarQueryPath
# add parameter key 'source' with value [epp|soap|rest]

use
    DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator::ScriptHelpers
    'schema_from_schema_loader';

schema_from_schema_loader(
    { naming => { ALL => 'v8', force_ascii => 1 } },
    sub {
        my ( $schema, $versions ) = @_;

        my $steps_rs = $schema->resultset('Step');

        say "Rename 'VarQueryPath[EPP|SOAP|REST]' to 'VarQueryPath'\n"
            . "add parameter key 'source' with value [epp|soap|rest]\n";

        while ( my $step = $steps_rs->next ) {
            if ($step->type eq 'VarQueryPathEPP') {
                update_with_source($step, '_epp_response');
            }
            elsif ($step->type eq 'VarQueryPathSOAP') {
                update_with_source($step, '_soap_response');
            }
            elsif ($step->type eq 'VarQueryPathREST') {
                update_with_source($step, '_rest_response');
            }
        }
    }
);

sub update_with_source {
    my ( $step, $source ) = @_;

    say "Updating step " . $step->id;

    # because DBIDH does not inflate $step->parameters to JSON
    # we do it manually with raw column data as source

    my $params_raw = $step->get_column('parameters');

    use JSON qw/ encode_json decode_json /;
    my $params = decode_json($params_raw);

    say "\told: ";
    say "\ttype: " . $step->type;
    use Data::Dumper;
    say "\t" . Dumper($params);

    $params->{source} = $source;
    $step->set_column( 'parameters' => encode_json($params) );
    $step->type('VarQueryPath');
    $step->update();

    say "\tnew:";
    say "\ttype: " . $step->type;
    say "\t" . Dumper($params);
}
