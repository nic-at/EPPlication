#!/usr/bin/env perl
use Dir::Self;
use lib __DIR__ . "/../lib";
use EPPlication::TestKit;

my $sql  = "SELECT id, name FROM foo";
my $name = 'dummy1';
my $results = [
                [ qw/ id name / ],
                [ 1, $name ],
                [ 2, 'dummy2' ],
              ];

my $schema = EPPlication::Util::get_schema();

my $user = $schema->resultset('User')->first;
my $branch = $schema->resultset('Branch')->single({name=>'master'});
my $test1 = $schema->resultset('Test')->create( { branch => $branch, name => 'test1' } );
ok( $test1, "test1 created" );
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
        name       => 'Set db_host',
        parameters => {
            variable => 'db_host',
            value    => 'localhost',
            global   => 1,
        },
    },
    {
        type       => 'VarVal',
        name       => 'Set db_port',
        parameters => {
            variable => 'db_port',
            value    => '5432',
            global   => 1,
        },
    },
    {
        type       => 'VarVal',
        name       => 'Set db_database',
        parameters => {
            variable => 'db_database',
            value    => 'epplication2',
            global   => 1,
        },
    },
    {
        type       => 'VarVal',
        name       => 'Set db_username',
        parameters => {
            variable => 'db_username',
            value    => 'epplication',
            global   => 1,
        },
    },
    {
        type       => 'VarVal',
        name       => 'Set db_password',
        parameters => {
            variable => 'db_password',
            value    => 'epplication',
            global   => 1,
        },
    },
    {
        type       => 'DBConnect',
        name       => 'Connect to DB server',
        parameters => {
            host     => '[% db_host %]',
            port     => '[% db_port %]',
            database => '[% db_database %]',
            username => '[% db_username %]',
            password => '[% db_password %]',
        },
    },
    {
        type       => 'DB',
        name       => 'send DB request',
        parameters => {
            var_result => 'db_response__',
            sql        => $sql,
        },
    },
    {
        type       => 'VarQueryPath',
        name       => 'get name from first db row',
        parameters => {
            var_result => 'name_from_db',
            input      => '[% db_response__ %]',
            query_path => '/*[0]/name',
        },
    },
    {
        type       => 'VarCheck',
        name       => 'check name from first db row',
        parameters => {
            variable => 'name_from_db',
            value    => $name,
        },
    },
    {
        type       => 'DBDisconnect',
        name       => 'Disconnect from DB server',
        parameters => {},
    },
);

for my $step_data (@steps) {
    my $step = $test1->steps->create($step_data);
    ok($step, "Step '" . $step_data->{name} . "' created");
}

{
    my $test_env = EPPlication::Util::get_test_env();

    setup_dbd_mock($test_env);

    my $stats = $job->run($test_env);
    ok(!$stats->{errors}, 'no errors');

    # print details of erroneous step result for faster debugging
    for ( $job->step_results->default_order->all ) {
        diag $_->type . ': ' . $_->name . "\n" . $_->details if $_->status eq 'error';
    }

    # +1 for root node (1), +1 for test root node (1.1)
    is($stats->{num_steps}, scalar(@steps) + 2, 'num_steps is correct');
}

$test1->delete;
ok(!$test1->in_storage, "test1 not in storage");
$job->delete;
ok(!$job->in_storage, "job not in storage");

done_testing();

sub setup_dbd_mock {
    my ($test_env) = @_;

    my $db_client = $test_env->{db_client};

    # set DBD::Mock as the driver to use
    $db_client->driver('Mock');

    # after the 'client' attribute has been set we need to add
    # the results we want to mock. we cannot add a 'trigger'
    # via Moose meta programming so we replace the 'client'
    # attribute with a clone and add a trigger to the clone.
    my $mock_add_rs = sub {
                              my ($self) = @_;
                              $self->client->{mock_add_resultset} = {
                                  sql     => $sql,
                                  results => $results,
                              };
                          };
    $db_client->meta->make_mutable;
    my $x = $db_client->meta->get_attribute('client')->clone( name => 'client', trigger => $mock_add_rs );
    $db_client->meta->add_attribute($x);
}
