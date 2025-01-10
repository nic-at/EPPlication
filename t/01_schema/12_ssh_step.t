#!/usr/bin/env perl
use Dir::Self;
use lib __DIR__ . "/../lib";
use EPPlication::TestKit;
use Encode qw/ encode_utf8 /;

SKIP: {
    skip(
        'Make sure the SSH key in directory ssh_keys is allowed to connect '
        . 'to localhost (e.g. ssh-copy-id -i ssh_keys/id_ed25519 foobar@localhost) and set '
        . 'EPPLICATION_TESTSSH=1 EPPLICATION_TESTSSH_USER=foobar to run SSH Steptests.',
        1
    )
      unless ( defined $ENV{EPPLICATION_TESTSSH}
          && defined $ENV{EPPLICATION_TESTSSH_USER} );

    # ä in perl internal format
    #SV = PV(0x5246ff0) at 0xdbf9a8
    #  REFCNT = 1
    #  FLAGS = (PADMY,POK,pPOK,UTF8)
    #  PV = 0x5263140 "\303\244"\0 [UTF8 "\x{e4}"]
    #  CUR = 2
    #  LEN = 1
    my $umlaut_a = pack( 'U', 0x00e4 );
    my $data     = '123' . $umlaut_a . '456';

    my $schema = EPPlication::Util::get_schema();

    my $branch = $schema->resultset('Branch')->single({name=>'master'});
    my $test = $schema->resultset('Test')->create({branch=>$branch,name=>'test'});
    ok($test, "test created");
    my $user = $schema->resultset('User')->first;
    my @steps = (
        {
            type       => 'SSH',
            name       => 'ssh',
            parameters => {
                var_stdout => 'ssh_stdout',
                ssh_host   => 'localhost',
                ssh_port   => 22,
                ssh_user   => $ENV{EPPLICATION_TESTSSH_USER},
                command    => 'echo "foo" | md5sum',
            },
        },
        {
            type       => 'SSH',
            name       => 'ssh_sleep',
            parameters => {
                var_stdout => 'ssh_stdout',
                ssh_host   => 'localhost',
                ssh_port   => 22,
                ssh_user   => $ENV{EPPLICATION_TESTSSH_USER},
                command    => 'sleep 2',
            },
        },
        {
            type       => 'SSH',
            name       => 'ssh_utf8',
            parameters => {
                var_stdout => 'ssh_stdout',
                ssh_host   => 'localhost',
                ssh_port   => 22,
                ssh_user   => $ENV{EPPLICATION_TESTSSH_USER},
                command    => "echo -n '$data'",
            },
        },
    );

    for my $step_data (@steps) {
        my $step = $test->steps->create($step_data);
        ok($step, "Step '" . $step_data->{name} . "' created in test");
    }

    my $job = $schema->resultset('Job')->create(
        {
            test_id   => $test->id,
            type      => 'test',
            user_id   => $user->id,
        }
    );
    ok($job, "job created");

    my $test_env = EPPlication::Util::get_test_env();

    # override step_timeout, this will cause a timeout error
    $test_env->{step_timeout} = 1;

    my $stats    = $job->run($test_env);
    is($stats->{errors}, 1, 'job has 1 error');
    my $num_steps = scalar(@steps);
    $num_steps += 2; # +1 for root node (1), +1 for test root node (1.1)
    is($stats->{num_steps}, $num_steps, 'num_steps is correct');

    for my $result ($job->step_results->default_order->all) {
        diag $result->name . ":\n" . $result->details if $result->status eq 'error';
        if ( $result->type eq 'SSH' ) {
            if( $result->name eq 'ssh') {
                is($result->status, "ok", "Step '" . $result->name. "' result status is 'ok'");
                like($result->details, qr/d3b07384d113edec49eaa6238ad5ff00/, "Correct command output received.");
            }
            elsif( $result->name eq 'ssh_sleep') {
                is($result->status, "error", "Step '" . $result->name. "' result status is 'error'");
                like($result->details, qr/sleep\ 2/, "Correct command has been executed.");
                like(
                    $result->details,
                    qr/Timeout\.\ Aborted\ step\ after\ 1\ seconds/,
                    "Timeout error message received."
                );
            }
            elsif( $result->name eq 'ssh_utf8') {
                is($result->status, "ok", "Step '" . $result->name. "' result status is 'ok'");
                like($result->details, qr/$data/, "Correctly encoded  command output received.");
            }
            else {
                fail('Unknown step name: ' . $result->name);
            }
        }
        else {
            is($result->status, "ok", "Step '" . $result->name. "' result status is 'ok'");
        }
    }

    $test->delete;
    ok(!$test->in_storage, "test not in storage");
    $job->delete;
    ok(!$job->in_storage, "job not in storage");
}

done_testing();
