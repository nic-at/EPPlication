#!/usr/bin/env perl
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use EPPlication::TestKit;
my $schema = EPPlication::Util::get_schema();

my $branch = $schema->resultset('Branch')->single({name=>'master'});
my $test = $schema->resultset('Test')->create( { branch => $branch, name => 'varcheckregexp_test' } );
ok( $test, "test created" );

my $user = $schema->resultset('User')->first;
my $job  = $schema->resultset('Job')->create(
    {
        test_id => $test->id,
        type    => 'test',
        user_id => $user->id,
    }
);
ok( $job, "job created" );

my @steps = (
    {
        type       => 'VarCheckRegExp',
        name       => 'regexp1',
        parameters => {
            regexp  => '\d',
            value   => '2',
            modifiers => 'xms',
        },
    },
    {
        type       => 'VarCheckRegExp',
        name       => 'regexp2',
        parameters => {
            regexp  => '\d',
            value   => 'a',
            modifiers => 'xms',
        },
    },
    {
        type       => 'VarCheckRegExp',
        name       => 'regexp3',
        parameters => {
            regexp  => '\d \d',
            value   => '12',
            modifiers => 'xms',
        },
    },
    {
        type       => 'VarCheckRegExp',
        name       => 'regexp4',
        parameters => {
            regexp  => '\d \d',
            value   => '12',
            modifiers => '',
        },
    },
);

for my $step_data (@steps) {
    my $step = $test->steps->create($step_data);
    ok($step, "Step '" . $step_data->{name} . "' created in test");
}

my $test_env = EPPlication::Util::get_test_env();
my $stats    = $job->run($test_env);
is( $stats->{errors}, 2, 'we expect 2 errors' );

# print details of erroneous step result for faster debugging
for ( $job->step_results->default_order->all ) {
    if ( $_->name ne 'regexp2' or $_->name ne 'regexp4' ) { # regexp2 and regexp4 are supposed to fail
        diag $_->name . ":\n" . $_->details if $_->status eq 'error';
    }
}

my $num_steps = scalar @steps + 2;
is($stats->{num_steps}, $num_steps, 'num_steps is correct');

$test->delete;
ok( !$test->in_storage, "test not in storage" );

done_testing();
