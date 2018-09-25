#!/usr/bin/env perl
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use EPPlication::TestKit;
use EPPlication::CLI;
use File::Temp qw/ tempfile /;
use Path::Class;

SKIP: {
    skip("Start EPPlication server with 'CATALYST_CONFIG_LOCAL_SUFFIX=testing plackup -Ilib  epplication.psgi --port 3000' and run prove with EPPLICATION_HOST=localhost EPPLICATION_PORT=3000 to run CLI tests.", 1)
      unless ( defined $ENV{ EPPLICATION_HOST } && defined $ENV{ EPPLICATION_PORT } );

    my $schema = EPPlication::Util::get_schema();
    my $host = 'http://' . $ENV{EPPLICATION_HOST};
    my $port = $ENV{EPPLICATION_PORT};
    my $cli  = EPPlication::CLI->new( host => $host, port => $port );

    ok(
        !$cli->login( 'foo321', 'bar321' ),
        'login fails with invalid credentials'
    );
    ok( $cli->login( 'testuser', 'testpassword' ), 'login ok' );

    # lookup versions
    my $versions_hash = $cli->get_version();
    ok( defined($versions_hash), 'got versions.' );
    ok( defined($versions_hash->{EPPlication}), 'got EPPlication version');
    ok( defined($versions_hash->{database}), 'got database version');

    my $branch_name = 'master';
    my $branch_id = $cli->get_branch_id_by_name( $branch_name );
    ok( defined($branch_id), 'branch_id found by name.' );

    my $config_name = 'config_001';
    {
        # create dummy config
        my $config      = $schema->resultset('Test')->create(
            {   name      => $config_name,
                branch_id => $branch_id,
                steps     => [
                    {   name       => 'some_config_step',
                        type       => 'Comment',
                        parameters => { comment => 'dummy config', },
                    },
                ],
            }
        );
    }
    my $config_id = $cli->get_test_id_by_name( $config_name, $branch_id );
    ok( defined($config_id), 'config id found by name.' );

    # create dummy test so we can get test_id by name
    my $test_name = 'some_test_name';
    my $test = $schema->resultset('Test')->create(
        {
            name      => $test_name,
            branch_id => $branch_id,
            steps => [
                {
                    name       => 'some_step',
                    type       => 'Comment',
                    parameters => {
                        comment => 'lorem ipsum',
                    },
                },
                {
                    name       => 'some_other_step',
                    type       => 'VarVal',
                    parameters => {
                        variable => 'foo',
                        value    => 'bar',
                        global   => 1,
                    },
                }
            ],
        }
    );
    ok( $test, 'test created' );
    is( $test->steps->count, 2,  'test has 2 steps' );

    my $test_id;
    {
        $test_id = $cli->get_test_id_by_name( $test_name, $branch_id );
        diag("Test ID: $test_id");
        ok( defined($test_id), 'test_id found by name.' );
    }
    {
        $test_id = $cli->get_test_id_by_name( $test_name );
        diag("Test ID: $test_id");
        ok( defined($test_id), 'test_id found by name (lookup without branch param).' );
    }

    # job does not exist
    my $job_result;
    $job_result = $cli->get_job( 1337 );
    ok( !defined($job_result), 'job not found.' );

    my $job_id = $cli->create_job( { test_id => $test_id, config_id => $config_id } );
    ok( defined($job_id), "job created. (id: $job_id)" );

    my $job = $schema->resultset('Job')->find($job_id);
    ok( defined $job, 'job found in DB' );

    $job_result = $cli->get_job($job_id);
    is( $job_result->{status}, 'pending', 'job is queued' );

    my $test_env = EPPlication::Util::get_test_env();
    my $stats    = $job->run($test_env);
    ok(!exists $stats->{errors}, 'no errors');

    $job_result = $cli->get_job($job_id);
    is( $job_result->{status}, 'finished', 'job finished' );

    # this creates a file on the fs running the EPPlication server
    my $location = $cli->export_job($job_id);
    like(
        $location,
        # http://localhost:3000/api/job/file/2018/06/13/20180613_id1.txt.bz'
        qr{$host:$port/api/job/file/\d{4}.+\d{2}.+\d{2}.+\d{8}_id\d+\.txt\.bz2},
        'valid job export location format'
    );

    # download job report
    {
        my ($fh, $filename) = tempfile( UNLINK => 1 );
        $cli->download_job_report($location, $filename);
        ok( -f $filename, "downloaded file $filename is a plain file." );
        ok( -s $filename, "$filename has non-zero size." );
    }

    ok( $cli->logout, 'logout ok' );

    # download job report
    {
        my ($fh, $filename) = tempfile( UNLINK => 0 );
        like(
            exception { $cli->download_job_report($location, $filename); },
            qr/^access\ denied,\ authentication\ needed\.$/xms,
            'downloading job report if not logged in raises exception'
        );
        ok( -f $filename, "tmp file $filename exists and is a plain file." );
        is( -s $filename, 0, "$filename has zero size." );
    }

    {
        # delete job export file on webserver
        my $epplication_config = EPPlication::Util::get_config();
        my $job_export_dir = $epplication_config->{'Model::DB'}{job_export_dir};
        my @components     = file($location)->components;
        my @rel_components = @components[ -4 .. -1 ];
        my $rel_location   = file(@rel_components);
        my $file           = file( $job_export_dir, $rel_location );
        diag 'Unlinking remote job export file: ' . $file->stringify;
        $file->remove;
    }

    $job->delete;
    ok(!$job->in_storage, "job not in storage");
    $test->delete;
    ok(!$test->in_storage, "test not in storage");
    my $config = $schema->resultset('Test')->single;
    $config->delete;
    ok(!$config->in_storage, "config not in storage");
};

done_testing();
