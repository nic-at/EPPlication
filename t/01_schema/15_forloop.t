#!/usr/bin/env perl
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use EPPlication::TestKit;

my $schema = EPPlication::Util::get_schema();

my $branch = $schema->resultset('Branch')->single({name=>'master'});
my $test_outer = $schema->resultset('Test')->create( { branch => $branch, name => 'test_outer' } );
my $test_inner = $schema->resultset('Test')->create( { branch => $branch, name => 'test_inner' } );
my $subtest    = $schema->resultset('Test')->create( { branch => $branch, name => 'subtest' } );
ok( $test_outer, "test_outer created" );
ok( $test_inner, "test_inner created" );
ok( $subtest,    "subtest created" );

my $user = $schema->resultset('User')->first;
my $job  = $schema->resultset('Job')->create(
    {
        test_id => $test_outer->id,
        type    => 'test',
        user_id => $user->id,
    }
);
ok( $job, "job created" );

my @outer_array = ('a', ' b ', 'c'); # whitespace around 'b' should be trimmed in ForLoop::process
my @inner_array = qw/ 1 2 3 /;
my $outer_value = join( ',', @outer_array );
my $inner_value = join( ',', @inner_array );

my @steps_outer = (
    {
        type       => 'VarVal',
        name       => 'outer_array',
        parameters => {
            variable => 'outer_array',
            value    => '[{"name":"a"},{"name":"b"},{"name":"c"}]',
            global   => 1,
        },
    },
    {
        type       => 'ForLoop',
        name       => 'outer loop',
        parameters => {
            subtest_id => $test_inner->id,
            variable   => 'hash_outer',
            values     => '[% outer_array %]',
        },
    },
);
my @steps_inner = (
    {
        type       => 'VarVal',
        name       => 'inner_array',
        parameters => {
            variable => 'inner_array',
            value    => '["1","2","3"]',
            global   => 1,
        },
    },
    {
        type       => 'ForLoop',
        name       => 'inner loop',
        parameters => {
            subtest_id => $subtest->id,
            variable   => 'foo_inner',
            values     => '[% inner_array %]',
        },
    },
);
my @steps_subtest = (
    {
        type       => 'VarQueryPath',
        name       => 'get foo_outer',
        parameters => {
            var_result => 'foo_outer',
            input      => '[% hash_outer %]',
            query_path => '//name',
        },
    },
    {
        type       => 'VarVal',
        name       => 'set foo',
        parameters => {
            variable => 'foo',
            value    => '[% foo_outer %]-[% foo_inner %]',
            global   => 1,
        },
    },
);

for my $step_data (@steps_outer) {
    my $step = $test_outer->steps->create($step_data);
    ok($step, "Step '" . $step_data->{name} . "' created in test_outer");
}
for my $step_data (@steps_inner) {
    my $step = $test_inner->steps->create($step_data);
    ok($step, "Step '" . $step_data->{name} . "' created in test_inner");
}
for my $step_data (@steps_subtest) {
    my $step = $subtest->steps->create($step_data);
    ok($step, "Step '" . $step_data->{name} . "' created in subtest");
}

my $test_env = EPPlication::Util::get_test_env();
my $stats    = $job->run($test_env);
ok( !exists $stats->{errors}, 'no errors' );
my $num_steps =   1                    # root node (1)
                + 1                    # test root node (1.1)
                + scalar(@steps_outer)
                + scalar(@outer_array) # outer ForLoop
                * (
                        2              # each ForLoop iteration adds a VarVal and a SubTest step
                      + scalar(@steps_inner)
                      + scalar(@inner_array) # inner ForLoop
                      * ( 2 + scalar(@steps_subtest) )
                  );

is($stats->{num_steps}, $num_steps, 'num_steps is correct');

my @expected = qw/
  a-1
  a-2
  a-3
  b-1
  b-2
  b-3
  c-1
  c-2
  c-3
  /;
my $count = 0;
for my $result ($job->step_results->default_order->all) {
    diag $result->details if $result->status eq 'error';
    if ( $result->details =~ m/Value:\s+([a-z]-[1-3])$/xms ) {
        is(
            $1,
            $expected[$count],
            'got expected result in correct order (' . $expected[$count] . ')'
        );
        $count++;
    }
}

$test_outer->delete;
ok( !$test_outer->in_storage, "test_outer not in storage" );
$test_inner->delete;
ok( !$test_inner->in_storage, "test_inner not in storage" );
$subtest->delete;
ok( !$subtest->in_storage, "subtest not in storage" );
$job->delete;
ok( !$job->in_storage, "job not in storage" );

done_testing();
