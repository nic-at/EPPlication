#!/usr/bin/env perl
use Dir::Self;
use lib __DIR__ . "/../lib";
use EPPlication::TestKit;

my $schema = EPPlication::Util::get_schema();

my $branch = $schema->resultset('Branch')->single({name=>'master'});
my $test1 = $schema->resultset('Test')->create({branch=>$branch,name=>'test1'});
ok($test1, "test1 created");
my $user = $schema->resultset('User')->first;
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
        name       => 'Set var_global',
        parameters => {
            variable => 'var_global',
            value    => '--foobar--',
            global   => 1,
        },
    },
    {
        type       => 'VarVal',
        name       => 'Set var_default',
        parameters => {
            variable => 'var_default',
            value    => '--foobar--',
            global   => 0,
        },
    },
    {
        type       => 'PrintVars',
        name       => 'print vars before ClearVars',
        parameters => { filter => '' },
    },
    {
        type       => 'ClearVars',
        name       => 'clear stash',
        parameters => {},
    },
    {
        type       => 'PrintVars',
        name       => 'print vars after ClearVars',
        parameters => { filter => '' },
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

for my $result ($job->step_results->default_order->all) {
    if ( $result->type eq 'PrintVars' ) {
        is($result->status, "ok", "Step '" . $result->name. "' result status is 'ok'");
        if ($result->name eq 'print vars before ClearVars') {
            like($result->details, qr/var_global/xms, 'var_global is in stash');
            like($result->details, qr/var_default/xms, 'var_default is in stash');
        }
        elsif ($result->name eq 'print vars after ClearVars') {
            like($result->details, qr/var_global/xms, 'var_global is in stash');
            unlike($result->details, qr/var_default/xms, 'var_default is in stash');
        }
    }
    else {
        is($result->status, "ok", "Step '" . $result->name. "' result status is 'ok'");
    }
}

$test1->delete;
ok(!$test1->in_storage, "test1 not in storage");
$job->delete;
ok(!$job->in_storage, "job not in storage");

done_testing();
