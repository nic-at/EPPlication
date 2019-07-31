#!/usr/bin/env perl
use Dir::Self;
use lib __DIR__ . "/../lib";
use EPPlication::TestKit;

my $schema = EPPlication::Util::get_schema();

my $branch = $schema->resultset('Branch')->single({name=>'master'});
my $test1 = $schema->resultset('Test')->create({branch=>$branch,name=>'test1'});
ok($test1, "test1 created");
my $test2 = $schema->resultset('Test')->create({branch=>$branch,name=>'test2'});
ok($test2, "test2 created");
my $user = $schema->resultset('User')->first;
my $job = $schema->resultset('Job')->create(
    {
        test_id   => $test1->id,
        type      => 'test',
        user_id   => $user->id,
    }
);
ok($job, "job created");

my @steps1 = (
    {
        type       => 'SubTest',
        name       => 'ssh subtest',
        parameters => {
            subtest_id => $test2->id,
        },
    },
);
my @steps2 = (
    {
        type       => 'SSH',
        name       => 'ssh',
        parameters => {
            var_stdout => 'ssh_stdout',
            ssh_host   => 'localhost',
            ssh_port   => 22,
            ssh_user   => 'unknownuser'.sprintf('%03d',int(rand(999))),
            command    => 'ls -lh',
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

my $test_env = EPPlication::Util::get_test_env();
my $stats    = $job->run($test_env);
is($stats->{errors}, 1, 'one error because no SSH keys present in test suite');
my $num_steps = scalar(@steps1) + scalar(@steps2);
$num_steps += 2; # +1 for root node (1), +1 for test root node (1.1)
is($stats->{num_steps}, $num_steps, 'num_steps is correct');

for my $result ($job->step_results->default_order->all) {
    if ( $result->type eq 'VarCheck' ) {
        is($result->status, "success", "Step '" . $result->name. "' result status is 'success'");
    }
    elsif ( $result->type eq 'SSH' ) {
        is($result->status, "error", "Step '" . $result->name. "' result status is 'error'");
        like($result->details, qr/LIBSSH2_ERROR_PUBLICKEY_UNRECOGNIZED/, "Authentication error found.");
    }
    else {
        is($result->status, "ok", "Step '" . $result->name. "' result status is 'ok'");
    }
}

$test1->delete;
ok(!$test1->in_storage, "test1 not in storage");
$test2->delete;
ok(!$test2->in_storage, "test2 not in storage");
$job->delete;
ok(!$job->in_storage, "job not in storage");

done_testing();
