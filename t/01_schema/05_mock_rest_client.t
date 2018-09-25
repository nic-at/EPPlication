#!/usr/bin/env perl
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use EPPlication::TestKit;
use Encode qw/ encode_utf8 /;

# ä in perl internal format
#SV = PV(0x5246ff0) at 0xdbf9a8
#  REFCNT = 1
#  FLAGS = (PADMY,POK,pPOK,UTF8)
#  PV = 0x5263140 "\303\244"\0 [UTF8 "\x{e4}"]
#  CUR = 2
#  LEN = 1
my $umlaut_a = pack( 'U', 0x00e4 );

my $username = "dummy1_$umlaut_a";
my $response = qq/{ "response": "1", "username": "$username", "email": "foo\@bar.at" }/;
my $response_utf8 = encode_utf8($response);
my $request = qq/{ "request": "1", "username": "$username", "email": "foo\@bar.at" }/;
my $request_utf8 = encode_utf8($request);
my $response_csv = qq/"response","username","email"\n"1","$username","foo\@bar.at"/;
my $response_csv_utf8 = encode_utf8($response_csv);

my $schema = EPPlication::Util::get_schema();

my $user = $schema->resultset('User')->first;
my $branch = $schema->resultset('Branch')->single({name=>'master'});
my $test1 = $schema->resultset('Test')->create({branch=>$branch,name=>'test1'});
ok($test1, "test1 created");
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
        name       => 'Set rest_host',
        parameters => {
            variable => 'rest_host',
            value    => 'https://rest.foobar.at',
            global   => 1,
        },
    },
    {
        type       => 'VarVal',
        name       => 'Set rest_port',
        parameters => {
            variable => 'rest_port',
            value    => '1337',
            global   => 1,
        },
    },
    {
        type       => 'VarVal',
        name       => 'Set rest_headers_json',
        parameters => {
            variable => 'rest_headers_json',
            value    => '{ "Accept":"application/json" }',
            global   => 1,
        },
    },
    {
        type       => 'VarVal',
        name       => 'Set rest_headers_csv',
        parameters => {
            variable => 'rest_headers_csv',
            value    => '{ "Accept":"text/csv" }',
            global   => 1,
        },
    },
    {
        type       => 'REST',
        name       => 'send REST request',
        parameters => {
            host          => '[% rest_host %]',
            port          => '[% rest_port %]',
            path          => '/registry/rest/registrar/dummy1',
            headers       => '[% rest_headers_json %]',
            method        => 'PUT',
            body          => $request,
            var_result    => 'rest_result_json__',
            var_status    => 'rest_status__',
            check_success => 1,
            validate_json => 1,
        },
    },
    {
        type       => 'VarCheck',
        name       => 'check status of REST request',
        parameters => {
            variable => 'rest_status__',
            value    => '200',
        },
    },
    {
        type       => 'VarQueryPath',
        name       => 'query REST result',
        parameters => {
            var_result => 'rest_content_json',
            input      => '[% rest_result_json__ %]',
            query_path => '/username',
        },
    },
    {
        type       => 'VarCheck',
        name       => 'check REST content',
        parameters => {
            variable => 'rest_content_json',
            value    => $username,
        },
    },
    {
        type       => 'REST',
        name       => 'send REST CSV request',
        parameters => {
            host          => '[% rest_host %]',
            port          => '[% rest_port %]',
            path          => '/registry/rest/registrar/dummy1',
            headers       => '[% rest_headers_csv %]',
            method        => 'GET',
            body          => $request,
            var_result    => 'rest_result_csv__',
            var_status    => 'rest_status_csv__',
            check_success => 1,
            validate_json => 1,
        },
    },
    {
        type       => 'Transformation',
        name       => 'transform HeaderRowCSV',
        parameters => {
            transformation => 'HeaderRowCSV',
            var_result     => 'header_row_from_csv',
            input          => '[% rest_result_csv__ %]',
        },
    },
    {
        type       => 'VarQueryPath',
        name       => 'get username from csv',
        parameters => {
            var_result => 'username_from_csv',
            input      => '[% header_row_from_csv %]',
            query_path => '/headers_rows/*[0]/username',
        },
    },
    {
        type       => 'VarCheck',
        name       => 'check username from csv',
        parameters => {
            variable => 'username_from_csv',
            value    => $username,
        },
    },
    {
        type       => 'PrintVars',
        name       => 'print vars',
        parameters => { filter => '' },
    },
);

for my $step_data (@steps) {
    my $step = $test1->steps->create($step_data);
    ok($step, "Step '" . $step_data->{name} . "' created");
}

{
    no warnings 'redefine';
    local *HTTP::Tiny::request = sub {
                                        my ( $self, $method, $url, $options ) = @_;
                                        is($options->{content}, $request_utf8, "request data encoded correctly");
                                        if (exists $options->{headers}{Accept} && $options->{headers}{Accept} =~ m!text/csv!xms) {
                                            return {
                                                protocol => 'HTTP/1.1',
                                                headers  => { 'content-type' => 'text/csv; charset=utf-8' },
                                                success  => 1,
                                                content  => $response_csv_utf8,
                                                status   => 200,
                                            };
                                        }
                                        else {
                                            return {
                                                protocol => 'HTTP/1.1',
                                                headers => { 'content-type' => 'application/json; charset=utf-8' },
                                                success  => 1,
                                                content  => $response_utf8,
                                                status   => 200,
                                            };
                                        }
                                    };
    my $test_env = EPPlication::Util::get_test_env();
    my $stats    = $job->run($test_env);
    ok(!$stats->{errors}, 'no errors');

    # print details of erroneous step result for faster debugging
    for ( $job->step_results->default_order->all ) {
        diag $_->name . ":\n" . $_->details if $_->status eq 'error';
        #diag $_->name . ":\n" . $_->details if $_->type eq 'PrintVars';
    }

    # +1 for root node (1), +1 for test root node (1.1)
    is($stats->{num_steps}, scalar(@steps) + 2, 'num_steps is correct');
}

$test1->delete;
ok(!$test1->in_storage, "test1 not in storage");
$job->delete;
ok(!$job->in_storage, "job not in storage");

done_testing();
