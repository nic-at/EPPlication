#!/usr/bin/env perl
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use EPPlication::TestKit;

my $schema = EPPlication::Util::get_schema();

# test with true and with false condition
my @conditions = (
    { condition => '[% 1 == 1 %]', adjust_num_steps => 0 },
    { condition => '[% 1 == 0 %]', adjust_num_steps => -1 },
);

my $branch = $schema->resultset('Branch')->single({name=>'master'});
for my $condition ( @conditions ) {
    my $test1 = $schema->resultset('Test')->create( { branch => $branch, name => 'test1' } );
    ok( $test1, "test1 created" );
    my $test2 = $schema->resultset('Test')->create( { branch => $branch, name => 'test2' } );
    ok( $test2, "test2 created" );
    my $user = $schema->resultset('User')->first;
    my @steps1 = (
        {
            type       => 'SubTest',
            name       => 'conditional subtest',
            condition  => $condition->{condition},
            parameters => {
                subtest_id => $test2->id,
            },
        },
    );
    my @steps2 = (
        {
            type       => 'VarVal',
            name       => 'set a',
            parameters => {
                global   => 0,
                variable => 'a',
                value    => 'foobar',
            },
        },
    );

    for my $step_data (@steps1) {
        my $step = $test1->steps->create($step_data);
        ok($step, "Step '" . $step_data->{name} . "' created in test1");
    }
    for my $step_data (@steps2) {
        my $step = $test2->steps->create($step_data);
        ok($step, "Step '" . $step_data->{name} . "' created in test2");
    }

    my $job = $schema->resultset('Job')->create(
        {
            test_id   => $test1->id,
            type      => 'test',
            user_id   => $user->id,
        }
    );
    ok($job, "job created");

    my $test_env = EPPlication::Util::get_test_env();

    my $stats    = $job->run($test_env);
    ok(!defined $stats->{errors}, 'job has no errors');
    my $num_steps = scalar(@steps1) + scalar(@steps2) + $condition->{adjust_num_steps};
    $num_steps += 2; # +1 for root node (1), +1 for test root node (1.1)
    is($stats->{num_steps}, $num_steps, 'num_steps is correct: ' . $num_steps);

    for my $result ($job->step_results->default_order->all) {
        is($result->status, "ok", "Step '" . $result->name. "' result status is 'ok'");
    }

    $test1->delete;
    ok(!$test1->in_storage, "test1 not in storage");
    $test2->delete;
    ok(!$test2->in_storage, "test2 not in storage");
    $job->delete;
    ok(!$job->in_storage, "job not in storage");
}

done_testing();
