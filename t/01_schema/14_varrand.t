#!/usr/bin/env perl
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
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

my @rands = (
    'foobar',
    'foobar\d+',
    '[a-zA-Z0-9]{5}',
    'foobar-[-,._/%]{10}',
);

my @steps1 = map {
    {
        type       => 'VarRand',
        name       => 'generate random string',
        parameters => {
            variable => 'rand_var',
            rand     => $_,
        },
    }
    } @rands;

for my $step_data (@steps1) {
    my $step = $test1->steps->create($step_data);
    ok($step, "Step '" . $step_data->{name} . "' created in test1");
}

my $test_env = EPPlication::Util::get_test_env();
my $stats    = $job->run($test_env);
ok(!exists $stats->{errors}, 'no errors');
my $num_steps = scalar(@steps1);
$num_steps += 2; # +1 for root node (1), +1 for test root node (1.1)
is($stats->{num_steps}, $num_steps, 'num_steps is correct');

my $varrandstepscounter = 0;
for my $result ($job->step_results->default_order->all) {
    if ( $result->type eq 'VarRand' ) {
        is($result->status, "ok", "Step '" . $result->name. "' result status is 'ok'");
        like($result->details, qr/$rands[$varrandstepscounter++]/, "random string matches pattern");
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
