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
        name       => 'set input',
        parameters => {
            variable => 'json',
            value    => qq/{
                             "foo1": { "baz": ["a","b","c"] },
                             "foo2": { "baz": ["d","e","f"] }
                        }/,
            global   => 0,
        },
    },
    {
        type       => 'VarQueryPath',
        name       => 'get foo1_baz',
        parameters => {
            var_result => 'foo1_baz',
            input      => '[% json %]',
            query_path => '//foo1/baz',
        },
    },
    {
        type       => 'DataCmp',
        name       => 'check foo1_baz',
        parameters => {
            value_a => '[%foo1_baz%]',
            value_b => '["a","b","c"]',
        },
    },
    {
        type       => 'VarQueryPath',
        name       => 'get bazes',
        parameters => {
            var_result => 'bazes',
            input      => '[% json %]',
            query_path => '//baz',
        },
    },
    {
        type       => 'PrintVars',
        name       => 'print',
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

# print details of erroneous step result for faster debugging
for ( $job->step_results->default_order->all ) {
    if ($_->type eq 'PrintVars') {
        if( $_->details =~ m/^\s*bazes\s*=>\s*"\[(\[.*\])\]",$/xms ) {
            pass('PrintVars contains bazes result in correct format.');
            # Data::DPath returns multiple results in unpredictable order.
            # ["a","b","c"],["d","e","f"] OR ["d","e","f"],["a","b","c"]
            my $two_array_refs = $1;
            like($two_array_refs, qr/\[\\"a\\",\\"b\\",\\"c\\"\]/xms, 'bazes contains a,b,c');
            like($two_array_refs, qr/\[\\"d\\",\\"e\\",\\"f\\"\]/xms, 'bazes contains d,e,f');
        }
        else {
            fail('PrintVars did not contain bazes result in correct format.');
        }
    }
    diag $_->type . ': ' . $_->name . "\n" . $_->details if $_->status eq 'error';
}

$test1->delete;
ok(!$test1->in_storage, "test1 not in storage");
$job->delete;
ok(!$job->in_storage, "job not in storage");

done_testing();
