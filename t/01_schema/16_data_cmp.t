#!/usr/bin/env perl
use Dir::Self;
use lib __DIR__ . "/../lib";
use EPPlication::TestKit;
my $schema = EPPlication::Util::get_schema();

my $branch = $schema->resultset('Branch')->single({name=>'master'});
my $test = $schema->resultset('Test')->create( { branch => $branch, name => 'data_cmp_test' } );
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
        type       => 'DataCmp',
        name       => 'cmp data',
        parameters => {
            value_a   => '{ "foo":"bar","2":"2"}',
            value_b   => '{ "2":"2","foo":"bar"}',
        },
    },
);

for my $step_data (@steps) {
    my $step = $test->steps->create($step_data);
    ok($step, "Step '" . $step_data->{name} . "' created in test");
}

my $test_env = EPPlication::Util::get_test_env();
my $stats    = $job->run($test_env);
ok( !exists $stats->{errors}, 'no errors' );

# print details of erroneous step result for faster debugging
for ( $job->step_results->default_order->all ) {
    diag $_->name . ":\n" . $_->details if $_->status eq 'error';
}

my $num_steps = scalar @steps + 2; # rootstep + test substep;
is($stats->{num_steps}, $num_steps, 'num_steps is correct');

$test->delete;
ok( !$test->in_storage, "test not in storage" );

done_testing();
