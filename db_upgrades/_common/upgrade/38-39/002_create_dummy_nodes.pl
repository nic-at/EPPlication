#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

# $max_nodes must match with custom SQL in file: db_upgrades/PostgreSQL/upgrade/38-39/001-auto.sql
my $max_nodes = 100;

use
  DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator::ScriptHelpers
  'schema_from_schema_loader';


schema_from_schema_loader(
    { naming => { ALL => 'v8', force_ascii => 1 } },
    sub {
        my ( $schema, $versions ) = @_;

        my $job_rs = $schema->resultset('Job');

        while ( my $job = $job_rs->next ) {
            say 'Add dummy subtests for job: ' . $job->id;

            my @nodes;
            push( @nodes,  _make_node($job->id, undef, 1) ); # root node

            my $root_node = 1;

            my $num_results = $job->step_results->count();
            my $num_dummy_nodes = int($num_results / $max_nodes) + 1;
            push( @nodes,  _make_node($job->id, $root_node, $_) )
              for (1 .. $num_dummy_nodes );

            # insert all the dummy nodes
            $job->step_results->populate( \@nodes );
        }
    }
);

sub _make_node {
    my ( $job_id, $node, $position ) = @_;
    return {
        job_id   => $job_id,
        node     => $node,
        position => $position,
        type     => 'SubTest',
        name     => 'dummy node',
        status   => 'ok',
        details  => 'Due to migration of old job reports the tree structure '
          . 'of this job does not reflect the structure of the original test.',
        step_id => undef,
        test_id => undef,
    };
}
