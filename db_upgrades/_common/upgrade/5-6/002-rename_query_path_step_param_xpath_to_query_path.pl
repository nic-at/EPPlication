#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

# schema upgrade v5-v6
# for all steps with type VarQueryPath*
# rename the step parameters key xpath to query_path
#
# file ../4-5/002-rename_query_path_step_param_xpath_to_query_path.pl
# didnt alter any steps because the type regexp was matching the old type
# VarXPath(EPP|SOAP|REST) instead of VarQueryPath(EPP|SOAP|REST)

use
    DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator::ScriptHelpers
    'schema_from_schema_loader';

schema_from_schema_loader(
    { naming => { ALL => 'v8', force_ascii => 1 } },
    sub {
        my ( $schema, $versions ) = @_;

        my $steps_rs = $schema->resultset('Step');
        while ( my $step = $steps_rs->next ) {
            if ($step->type =~ m/^VarQueryPath(EPP|SOAP|REST)$/xms) {
                say "Updating step " . $step->id
                  . ": rename parameters->{xpath} to parameters->{query_path}";

                # because DBIDH does not inflate $step->parameters to JSON
                # we do it manually with raw column data as source

                my $params_raw = $step->get_column('parameters');

                use Data::Dumper;
                use JSON qw/ encode_json decode_json /;
                my $params = decode_json($params_raw);

                say "\t old:";
                say "\t" . Dumper($params);

                $params->{query_path} = delete $params->{xpath};
                $step->set_column('parameters' => encode_json($params));
                $step->update();

                say "\tnew:";
                say "\t" . Dumper($params);
            }
        }
    }
);
