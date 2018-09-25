#!/usr/bin/env perl
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use EPPlication::TestKit;

my $schema = EPPlication::Util::get_schema();

my $branch = $schema->resultset('Branch')->single({name=>'master'});
my $test = $schema->resultset('Test')->create({branch=>$branch,name=>'test'});
ok($test, "test created");
my $user = $schema->resultset('User')->first;
my @steps = (
    {
        type       => 'DateFormat',
        name       => 'date',
        parameters => {
            variable => 'mydate',
            date     => 'now()',
            date_format_str => '%d-%m-%Y',
        },
    },
    {
        type       => 'VarVal',
        name       => 'date1',
        parameters => {
            variable => 'mydate1',
            value    => '2013-06-17T06:54:39.102245Z',
            global   => 0,
        },
    },
    {
        type       => 'VarVal',
        name       => 'date2',
        parameters => {
            variable => 'mydate2',
            value    => '2014-06-17T06:54:39.102245Z',
            global   => 0,
        },
    },
    {
        type       => 'DateAdd',
        name       => 'date3',
        parameters => {
            variable => 'mydate3',
            date     => '[% mydate1 %]',
            duration => '1 year',
        },
    },
    {
        type       => 'DateCheck',
        name       => 'check',
        parameters => {
            date_got      => '[% mydate3 %]',
            date_expected => '[% mydate2 %]',
            duration => '1 minute',
        },
    },
    {
        type       => 'DateCheck',
        name       => 'failing check',
        parameters => {
            date_got      => '[% mydate1 %]',
            date_expected => 'now()',
            duration => '1 minute',
        },
    },
);

for my $step_data (@steps) {
    my $step = $test->steps->create($step_data);
    ok($step, "Step '" . $step_data->{name} . "' created in test");
}

my $job = $schema->resultset('Job')->create(
    {
        test_id   => $test->id,
        type      => 'test',
        user_id   => $user->id,
    }
);
ok($job, "job created");

my $test_env = EPPlication::Util::get_test_env();

my $stats = $job->run($test_env);
is($stats->{errors}, 1, 'job has 1 error');
my $num_steps = scalar(@steps);
$num_steps += 2; # +1 for root node (1), +1 for test root node (1.1)
is($stats->{num_steps}, $num_steps, 'num_steps is correct');

for my $result ( $job->step_results->default_order->all ) {
    diag $result->name . ":\n" . $result->details if $result->status eq 'error';
    if ( $result->type eq 'DateFormat' ) {
        is( $result->status, "ok", "Step '" . $result->name . "' result status is 'ok'" );
        # the default format is: 2016-05-17T14:46:48.000000Z
        # we want to make sure the specified format is used
        like(
            $result->details,
            qr/\d\d-\d\d-\d\d\d\d[^T]?/,
            "Correct command output received."
        );
    }
    elsif ( $result->type eq 'DateCheck' ) {
        if ( $result->name eq 'failing check' ) {
            is( $result->status, "error", "Step '" . $result->name . "' failed as expected." );
            like(
                $result->details,
                qr/date_got\ exceeds\ lower\ boundary/,
                "Correct error msg received."
            );
        }
    }
}

$test->delete;
ok(!$test->in_storage, "test not in storage");
$job->delete;
ok(!$job->in_storage, "job not in storage");

done_testing();
