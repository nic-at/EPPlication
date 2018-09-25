#!/usr/bin/env perl
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use EPPlication::TestKit;
use Encode qw/ encode_utf8 /;

# utf8 encoding is not necessary for domain 'epplication.at'
# but future tests may include special chars.
my $domain      = "eppliction.at";
my $domain_utf8 = encode_utf8($domain);

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
        name       => 'Set whois_host',
        parameters => {
            variable => 'whois_host',
            value    => 'whois.foobar.at2',
            global   => 1,
        },
    },
    {
        type       => 'VarVal',
        name       => 'Set whois_port',
        parameters => {
            variable => 'whois_port',
            value    => '1234',
            global   => 1,
        },
    },
    {
        type       => 'VarVal',
        name       => 'Set domain',
        parameters => {
            variable => 'whois_domain',
            value    => $domain,
            global   => 1,
        },
    },
    {
        type       => 'Whois',
        name       => 'send Whois request',
        parameters => {
            host          => '[% whois_host %]',
            port          => '[% whois_port %]',
            domain        => '[% whois_domain %]',
            var_result    => 'whois_response__',
        },
    },
    {
        type       => 'VarCheck',
        name       => 'check Whois request',
        parameters => {
            variable => 'whois_response__',
            value    => $domain,
        },
    },
);

for my $step_data (@steps) {
    my $step = $test1->steps->create($step_data);
    ok($step, "Step '" . $step_data->{name} . "' created");
}

{
    no warnings 'redefine';
    local *EPPlication::Client::Whois::request = sub {
                                        my ( $self, $host, $port, $domain ) = @_;
                                        return ($domain_utf8, "$host:$port");
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
