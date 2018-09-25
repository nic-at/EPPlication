#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use JSON qw//;

# add parameter 'global' with default 0 to all VarVal Steps

use
  DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator::ScriptHelpers
  'schema_from_schema_loader';

schema_from_schema_loader(
    { naming => { ALL => 'v8', force_ascii => 1 } },
    sub {
        my ( $schema, $versions ) = @_;

        my $step_rs = $schema->resultset('Step')->search({ type => 'VarVal' });
        while ( my $step = $step_rs->next ) {
            say "Set parameter 'global => 0' for step " . $step->id;
            my $params_raw = $step->get_column('parameters');
            my $params = JSON->new->decode($params_raw);
            $params->{global} = 0;
            $step->set_column( 'parameters' => JSON->new->encode($params) );
            $step->update();
        }
    }
);

