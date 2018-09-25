#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

# schema upgrade v3-v4 replaces XPath with Data::DPath
# this script renames the step parameters key 'xml' to 'json'
# for all steps of type REST

use
    DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator::ScriptHelpers
    'schema_from_schema_loader';

schema_from_schema_loader(
    { naming => { ALL => 'v8', force_ascii => 1 } },
    sub {
        my ( $schema, $versions ) = @_;

        my $steps_rs = $schema->resultset('Step');
        while ( my $step = $steps_rs->next ) {
            if ($step->type eq 'REST') {
                say "Updating step " . $step->id . ": rename parameters->{xml} to parameters->{json}";

                # because DBIDH does not inflate $step->parameters to JSON
                # we do it manually with raw column data as source

                my $params_raw = $step->get_column('parameters');

                use Data::Dumper;
                use JSON qw/ encode_json decode_json /;
                my $params = decode_json($params_raw);

                say "\t old:";
                say "\t" . Dumper($params);

                $params->{json} = delete $params->{xml};
                $step->set_column('parameters' => encode_json($params));
                $step->update();

                say "\tnew:";
                say "\t" . Dumper($params);
            }
        }
    }
);
