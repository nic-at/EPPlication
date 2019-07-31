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
        name       => 'set value1',
        parameters => {
            variable => 'value1',
            value    => "a\nb\nc",
            global   => 0,
        },
    },
    {
        type       => 'VarVal',
        name       => 'set value2',
        parameters => {
            variable => 'value2',
            value    => "a\nb\nc",
            global   => 0,
        },
    },
    {
        type       => 'Diff',
        name       => 'diff',
        parameters => {
            variable => 'diff1',
            value1   => '[% value1 %]',
            value2   => '[% value2 %]',
        },
    },
    {
        type       => 'VarVal',
        name       => 'set value3',
        parameters => {
            variable => 'value3',
            value    => "a\n\nc",
            global   => 0,
        },
    },
    {
        type       => 'Diff',
        name       => 'diff error',
        parameters => {
            variable => 'diff2',
            value1   => '[% value1 %]',
            value2   => '[% value3 %]',
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

# print details of erroneous step result for faster debugging
for ( $job->step_results->default_order->all ) {
    diag $_->type . ': ' . $_->name . "\n" . $_->details if $_->status eq 'error';

    if ($_->name eq 'diff error') {
        like(
            $_->details,
            qr/a\s-b\s\+\s\ c/xms,
            'diff shows difference of values.'
        );
    }
}

$test1->delete;
ok(!$test1->in_storage, "test1 not in storage");
$job->delete;
ok(!$job->in_storage, "job not in storage");

done_testing();
