#!/usr/bin/env perl
use Dir::Self;
use lib __DIR__ . "/../lib";
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
my $request = <<"HERE";
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<soap:Envelope
 xmlns:namesp1="http://namespaces.soaplite.com/perl"
 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
 xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/"
 xmlns:xsd="http://www.w3.org/2001/XMLSchema"
 soap:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"
 xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
    <request>1</request>
    <username>$username</username>
    <email>foo\@bar.at</email>
</soap:Envelope>
HERE

my $response = <<"HERE";
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<soap:Envelope
 xmlns:namesp1="http://namespaces.soaplite.com/perl"
 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
 xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/"
 xmlns:xsd="http://www.w3.org/2001/XMLSchema"
 soap:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"
 xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
    <response>1</response>
    <username>$username</username>
    <email>foo\@bar.at</email>
</soap:Envelope>
HERE

my $request_utf8  = encode_utf8($request);
my $response_utf8 = encode_utf8($response);

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
        name       => 'Set soap_host',
        parameters => {
            variable => 'soap_host',
            value    => 'soap.foobar.at',
            global   => 1,
        },
    },
    {
        type       => 'VarVal',
        name       => 'Set soap_port',
        parameters => {
            variable => 'soap_port',
            value    => '1337',
            global   => 1,
        },
    },
    {
        type       => 'VarVal',
        name       => 'Set soap_path',
        parameters => {
            variable => 'soap_path',
            value    => '/soap',
            global   => 1,
        },
    },
    {
        type       => 'SOAP',
        name       => 'send SOAP frame',
        parameters => {
            host         => '[% soap_host %]',
            port         => '[% soap_port %]',
            path         => '[% soap_path %]',
            method       => 'POST',
            var_result   => 'soap_response__',
            body         => $request,
            validate_xml => 1,
        },
    },
    {
        type       => 'VarQueryPath',
        name       => 'query SOAP response',
        parameters => {
            var_result => 'soap_response',
            input      => '[% soap_response__ %]',
            query_path => '/Envelope/username',
        },
    },
    {
        type       => 'VarCheck',
        name       => 'check SOAP response',
        parameters => {
            variable => 'soap_response',
            value    => $username,
        },
    },
);

for my $step_data (@steps) {
    my $step = $test1->steps->create($step_data);
    ok($step, "Step '" . $step_data->{name} . "' created");
}

{
    no warnings 'redefine';
    local *HTTP::Tiny::request = sub {
                                     my ( $self, $method, $url, $args ) = @_;
                                     is($args->{content}, $request_utf8, "request data encoded correctly");
                                     return {
                                         protocol => 'HTTP/1.1',
                                         headers => { 'content-type' => 'application/xml; charset=utf-8' },
                                         success  => 1,
                                         content  => $response_utf8,
                                         status   => 200,
                                     };
                                 };
    my $test_env = EPPlication::Util::get_test_env();
    my $stats    = $job->run($test_env);
    ok(!$stats->{errors}, 'no errors');

    # print details of erroneous step result for faster debugging
    for ( $job->step_results->default_order->all ) {
        diag $_->name . ":\n" . $_->details if $_->status eq 'error';
    }

    # +1 for root node (1), +1 for test root node (1.1)
    is($stats->{num_steps}, scalar(@steps) + 2, 'num_steps is correct');
}

$test1->delete;
ok(!$test1->in_storage, "test1 not in storage");
$job->delete;
ok(!$job->in_storage, "job not in storage");

done_testing();
