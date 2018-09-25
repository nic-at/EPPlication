#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

# schema upgrade v14-v15
# this script changes all VarDate steps to VarVal steps and
# changes the step parameter key 'date' to 'value'

use
    DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator::ScriptHelpers
    'schema_from_schema_loader';

schema_from_schema_loader(
    { naming => { ALL => 'v8', force_ascii => 1 } },
    sub {
        my ( $schema, $versions ) = @_;

        my $steps_rs = $schema->resultset('Step');
        while ( my $step = $steps_rs->next ) {
            if ($step->type eq 'VarDate') {
                say "Updating step " . $step->id . ": change type from 'VarDate' to 'VarVal' and rename parameters->{date} to parameters->{value}";

                # because DBIDH does not inflate $step->parameters to JSON
                # we do it manually with raw column data as source

                my $params_raw = $step->get_column('parameters');

                use Data::Dumper;
                use JSON qw/ encode_json decode_json /;
                my $params = decode_json($params_raw);

                say "\told:";
                say "\ttype: " . $step->type;
                say "\t" . Dumper($params);

                $step->type('VarVal');

                $params->{value} = delete $params->{date};
                $step->set_column('parameters' => encode_json($params));
                $step->update();

                say "\tnew:";
                say "\ttype: " . $step->type;
                say "\t" . Dumper($params);
            }
        }
    }
);
