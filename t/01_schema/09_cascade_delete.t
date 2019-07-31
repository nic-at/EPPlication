#!/usr/bin/env perl
use Dir::Self;
use lib __DIR__ . "/../lib";
use EPPlication::TestKit;

my $schema = EPPlication::Util::get_schema();

my $branch = $schema->resultset('Branch')->single({name=>'master'});
my $config = $schema->resultset('Test')->create( { branch => $branch, name => 'config' } );
ok( $config, "config created" );
my $test = $schema->resultset('Test')->create( { branch => $branch, name => 'test' } );
ok( $test, "test created" );
my $user = $schema->resultset('User')->create( { name => 'testuser2', password => 'foobar2' } );
ok( $user, 'user created' );
my $job = $schema->resultset('Job')->create(
    {
        test_id   => $test->id,
        type      => 'test',
        user_id   => $user->id,
        config_id => $config->id,
    }
);
ok($job, "job created");

my @steps1 = (
    {
        type       => 'VarVal',
        name       => 'set a',
        parameters => {
            variable => 'a',
            value    => 1,
            global   => 1,
        },
    },
);
my @steps2 = (
    {
        type       => 'VarVal',
        name       => 'set b',
        parameters => {
            variable => 'b',
            value    => 2,
            global   => 0,
        },
    },
);

for my $step_data (@steps1) {
    my $step = $config->steps->create($step_data);
    ok($step, "Step '" . $step_data->{name} . "' created in config");
}
for my $step_data (@steps2) {
    my $step = $test->steps->create($step_data);
    ok($step, "Step '" . $step_data->{name} . "' created in test");
}

my $test_env = EPPlication::Util::get_test_env();
my $stats    = $job->run($test_env);
ok(!$stats->{errors}, 'no errors');
my $num_steps = scalar(@steps1) + scalar(@steps2);
# +1 for root node (1), +1 for test root node (1.2), +1 for config root node (1.1)
$num_steps += 3;
is($stats->{num_steps}, $num_steps, 'num_steps is correct');

#my $config_id = $config->id;
#like(
#    exception { $config->delete; },
#    qr/
#        execute\ failed.*
#        Key\ \(id\)=\($config_id\).*
#        is\ still\ referenced\ from\ table\ "job"
#    /xms,
#    "Exception when deleting config that is used in a job",
#);

#my $test_id = $test->id;
#like(
#    exception { $test->delete; },
#    qr/
#        execute\ failed.*
#        Key\ \(id\)=\($test_id\).*
#        is\ still\ referenced\ from\ table\ "job"
#    /xms,
#    "Exception when deleting test that is used in a job",
#);

is(
    exception { $config->delete; },
    undef,
    'config can be deleted even though used in job.'
);
ok(!$config->in_storage, "config not in storage");
$job->discard_changes(); # refresh from database
is($job->config_id, undef, 'config_id has been set to NULL');

is(
    exception { $test->delete; },
    undef,
    'test can be deleted even though used in job.'
);
ok(!$test->in_storage, "test not in storage");
$job->discard_changes(); # refresh from database
is($job->test_id, undef, 'test_id has been set to NULL');

is(
    exception { $user->delete; },
    undef,
    'user can be deleted even though used in job.'
);
ok(!$user->in_storage, "user not in storage");
$job->discard_changes(); # refresh from database
is($job->user_id, undef, 'user_id has been set to NULL');

$job->delete;
ok(!$job->in_storage, "job not in storage");

done_testing();
