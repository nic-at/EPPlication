#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use JSON;

# results of a job used to be an array of hashrefs serialized in column
# 'data' of table 'job'.
# take the array and create a row in table 'step_result' for each array item.

use
  DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator::ScriptHelpers
  'schema_from_schema_loader';

schema_from_schema_loader(
    { naming => { ALL => 'v8', force_ascii => 1 } },
    sub {
        my ( $schema, $versions ) = @_;

        my $job_rs = $schema->resultset('Job');

        while ( my $job = $job_rs->next ) {
            say 'Creating step results for job ' . $job->id;

            say "\tget data column";
            my $data_raw = $job->get_column('data');
            say "\tdeserialize data column";
            my $data     = from_json($data_raw);
            say "\tcreate step_result rows";

            # DBIx::Class::Ordered is not loaded when using
            # DBIx::Class::DeploymentHandler, so we have to
            # calculate the position value manually. (num_steps)
            my %stats = ();

            my @result_batch;
            for my $result (@$data) {

                $stats{num_steps}++;
                if ($result->{status} eq 'error') {
                    $stats{errors}++;
                }
                elsif ($result->{status} eq 'warning') {
                    $stats{warnings}++;
                }
                push(
                    @result_batch,
                    {
                        test_id => $result->{test_id},
                        step_id => $result->{step_id},
                        type    => $result->{type},
                        name    => $result->{name},
                        status  => $result->{status},
                        out     => defined $result->{out} ? $result->{out} : '',
                        in      => defined $result->{in} ? $result->{in} : '',
                        position => $stats{num_steps},
                    }
                );

                if (scalar @result_batch >= 5000) {
                    print "\tsteps: " . $stats{num_steps} . "\n";
                    $job->step_results->populate(\@result_batch);
                    @result_batch = ();
                }
            }
            print "\tsteps: " . $stats{num_steps} . "\n";
            $job->step_results->populate(\@result_batch);
            @result_batch = ();

            $job->update(
                {
                    num_steps => $stats{num_steps},
                    errors    => $stats{errors},
                    warnings  => $stats{warnings},
                    data      => '',
                }
            );

            say "\tcreated " . $stats{num_steps} . " step_results";
        }
    }
);
