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

my $row_1_h1  = 'foobarbaz1';
my $lc_str    = 'abcdef';
my $uc_str    = uc($lc_str);
my $undef_str = '{ "headers_rows": [{ "a":null,"b":7,"c":[{"f":9,"i":null}]}]}';
my $empty_str = '{ "headers_rows": [{ "b":7,"a":"","c":[{"f":9,"i":""}]}]}';

my @steps = (
    # xml2json Transformation
    {
        type       => 'Transformation',
        name       => 'transform Xml2Json',
        parameters => {
            transformation => 'Xml2Json',
            var_result     => 'json',
            input          => "<xml><foo>foostr</foo><bar>barstr</bar></xml>",
        },
    },
    {
        type       => 'VarQueryPath',
        name       => 'get json data',
        parameters => {
            var_result => 'foo_str',
            input      => '[% json %]',
            query_path => '/*/foo',
        },
    },
    {
        type       => 'VarCheck',
        name       => 'check foo_str',
        parameters => {
            variable => 'foo_str',
            value    => 'foostr',
        },
    },
    # header_row Transformation
    {
        type       => 'VarVal',
        name       => 'original header row data',
        parameters => {
            variable => 'header_row_original',
            value    => qq/{
                           "headers": [ "h1", "h2", "h3" ],
                           "rows":    [
                                         [ "$row_1_h1", "row_1_h2", "row_1_h3" ],
                                         [ "row_2_h1", "row_2_h2", "row_2_h3" ]
                                      ]
                        }/,
            global   => 0,
        },
    },
    {
        type       => 'Transformation',
        name       => 'transform HeaderRow data',
        parameters => {
            transformation => 'HeaderRow',
            var_result     => 'header_row_transformed',
            input          => '[%header_row_original%]',
        },
    },
    {
        type       => 'VarQueryPath',
        name       => 'get header_row data',
        parameters => {
            var_result => 'h1_first_row',
            input      => '[% header_row_transformed %]',
            query_path => '/headers_rows/*[0]/h1',
        },
    },
    {
        type       => 'VarCheck',
        name       => 'check h1 value of first row of header_row data',
        parameters => {
            variable => 'h1_first_row',
            value    => $row_1_h1,
        },
    },
    # uppercase Transformation
    {
        type       => 'VarVal',
        name       => 'set lc_str',
        parameters => {
            variable => 'lc_str',
            value    => $lc_str,
            global   => 0,
        },
    },
    {
        type       => 'Transformation',
        name       => 'transform Uppercase',
        parameters => {
            transformation => 'Uppercase',
            var_result     => 'uc_result',
            input          => $lc_str,
        },
    },
    {
        type       => 'VarCheck',
        name       => 'check uppercase transformation result',
        parameters => {
            variable => 'uc_result',
            value    => $uc_str,
        },
    },
    # undef2emptystr Transformation
    {
        type       => 'VarVal',
        name       => 'set undef_str',
        parameters => {
            variable => 'undef_str',
            value    => $undef_str,
            global   => 0,
        },
    },
    {
        type       => 'VarVal',
        name       => 'set empty_str',
        parameters => {
            variable => 'empty_str',
            value    => $empty_str,
            global   => 0,
        },
    },
    {
        type       => 'Transformation',
        name       => 'transform Undef2EmptyStr',
        parameters => {
            transformation => 'Undef2EmptyStr',
            var_result     => 'undef2emptystr_result',
            input          => '[% undef_str %]',
        },
    },
    {
        type       => 'DataCmp',
        name       => 'check undef2emptystr transformation result',
        parameters => {
            value_a => '[% undef2emptystr_result %]',
            value_b => '[% empty_str %]',
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
}

$test1->delete;
ok(!$test1->in_storage, "test1 not in storage");
$job->delete;
ok(!$job->in_storage, "job not in storage");

done_testing();
