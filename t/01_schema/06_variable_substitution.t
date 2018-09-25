#!/usr/bin/env perl
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use EPPlication::TestKit;

my $schema = EPPlication::Util::get_schema();

my $user = $schema->resultset('User')->first;
my $branch = $schema->resultset('Branch')->single({name=>'master'});
my $test1 = $schema->resultset('Test')->create({branch=>$branch,name=>'test1'});
ok($test1, "test1 created");
my $job = $schema->resultset('Job')->create(
    {
        test_id   => $test1->id,
        type      => 'test',
        user_id   => $user->id,
    }
);
ok($job, "job created");

my @steps = (
    {
        type       => 'VarVal',
        name       => 'Set var_a',
        parameters => {
            variable => 'var_a',
            value    => '--foobar--',
            global   => 0,
        },
    },
    {
        type       => 'VarVal',
        name       => 'Set var_b',
        parameters => {
            variable => 'var_b',
            value    => '[% var_a %]',
            global   => 0,
        },
    },
    {
        type       => 'VarCheck',
        name       => 'check values',
        parameters => {
            variable => 'var_b',
            value    => '[% var_a %]',
        },
    },
);

for my $step_data (@steps) {
    my $step = $test1->steps->create($step_data);
    ok($step, "Step '" . $step_data->{name} . "' created");
}

my $test_env = EPPlication::Util::get_test_env();
my $stats    = $job->run($test_env);
ok(!$stats->{errors}, 'no errors');
# +1 for root node (1), +1 for test root node (1.1)
is($stats->{num_steps}, scalar(@steps) + 2, 'num_steps is correct');

$test1->delete;
ok(!$test1->in_storage, "test1 not in storage");
$job->delete;
ok(!$job->in_storage, "job not in storage");

done_testing();
