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
<epp
 xmlns="urn:ietf:params:xml:ns:epp-1.0"
 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
 xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0
 epp-1.0.xsd">
    <request>1</request>
    <username>$username</username>
    <email>foo\@bar.at</email>
</epp>
HERE

my $response = <<"HERE";
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<epp
 xmlns="urn:ietf:params:xml:ns:epp-1.0"
 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
 xsi:schemaLocation="urn:ietf:params:xml:ns:epp-1.0
 epp-1.0.xsd">
    <response>1</response>
    <username>$username</username>
    <email>foo\@bar.at</email>
</epp>
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
        name       => 'Set epp_host',
        parameters => {
            variable => 'epp_host',
            value    => 'epp.foobar.at',
            global   => 1,
        },
    },
    {
        type       => 'VarVal',
        name       => 'Set epp_port',
        parameters => {
            variable => 'epp_port',
            value    => '1337',
            global   => 1,
        },
    },
    {
        type       => 'VarVal',
        name       => 'Set epp_ssl',
        parameters => {
            variable => 'epp_ssl',
            value    => '1',
            global   => 1,
        },
    },
    {
        type       => 'EPPConnect',
        name       => 'Connect to EPP server',
        parameters => {
            var_result   => 'epp_response__',
            host         => '[% epp_host %]',
            port         => '[% epp_port %]',
            ssl          => '[% epp_ssl %]',
            ssl_use_cert => 0,
            ssl_cert     => '',
            ssl_key      => '',
        },
    },
    {
        type       => 'EPP',
        name       => 'send EPP request',
        parameters => {
            var_result   => 'epp_response__',
            body         => $request,
            validate_xml => 1,
        },
    },
    {
        type       => 'VarQueryPath',
        name       => 'get EPP greeting',
        parameters => {
            var_result => 'epp_greeting',
            input      => '[% epp_response__ %]',
            query_path => '/epp/username',
        },
    },
    {
        type       => 'VarCheck',
        name       => 'check EPP greeting',
        parameters => {
            variable => 'epp_greeting',
            value    => $username,
        },
    },
    {
        type       => 'EPPDisconnect',
        name       => 'Disconnect from EPP server',
        parameters => {},
    },
);

for my $step_data (@steps) {
    my $step = $test1->steps->create($step_data);
    ok($step, "Step '" . $step_data->{name} . "' created");
}

{
    no warnings 'redefine';

    my $connected = 0; # return false for first request, true for following requests
    local *EPPlication::Client::EPP::connected = sub { return $connected++; };

    local *Net::EPP::Client::connect         = sub { return 1; };
    local *Net::EPP::Client::disconnect      = sub { return 1; };
    local *Net::EPP::Client::get_frame       = sub { return $response_utf8; };
    local *Net::EPP::Client::send_frame      = sub {
                                                  my ($self, $frame) = @_;
                                                  is($frame, $request_utf8, "request data encoded correctly");
                                                  return 1;
                                               };
    my $test_env = EPPlication::Util::get_test_env();
    my $stats    = $job->run($test_env);
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
