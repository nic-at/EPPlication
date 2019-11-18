#!/usr/bin/env perl
use Dir::Self;
use lib __DIR__ . "/lib";
use EPPlication::TestKit;
use HTTP::Tiny;
use HTTP::CookieJar;
use JSON::PP;

SKIP: {
    skip("Start EPPlication server with 'CATALYST_CONFIG_LOCAL_SUFFIX=testing plackup -Ilib  epplication.psgi --port 3000' and run prove with EPPLICATION_HOST=localhost EPPLICATION_PORT=3000 to run CLI tests.", 1)
      unless ( defined $ENV{ EPPLICATION_HOST } && defined $ENV{ EPPLICATION_PORT } );

    my $host = 'http://' . $ENV{EPPLICATION_HOST};
    my $port = $ENV{EPPLICATION_PORT};
    my $http = HTTP::Tiny->new(
            cookie_jar      => HTTP::CookieJar->new,
            default_headers => {
                'Accept'       => 'application/json',
                'Content-Type' => 'application/json; charset=utf-8',
            },
    );
    {
        my $content_raw = encode_json( { name => 'testuser', password => 'testpassword' } );
        my $res = $http->request(
            'POST',
            "$host:$port/api/login",
            { content => $content_raw },
        );
        my $status = $res->{status};
        is( $res->{status}, 200, 'login response status 200' );
    }

    {
        my $res = $http->request( 'GET', "$host:$port/api/user" );
        is( $res->{status}, 200, 'get user list via api, response status 200' );
        my $users = decode_json($res->{content});
        is(scalar @$users, 1, '1 user found.');
        is($users->[0]->{name}, 'testuser', 'correct user name');
        ok(!exists $users->[0]->{password}, 'we didnt send the users crypted pw');
    }

    my $schema      = EPPlication::Util::get_schema();
    my $branch_name = 'master';
    my $branch      = $schema->resultset('Branch')->find($branch_name, {key=>'branch_name'});
    ok( $branch, 'branch found by name.' );
    my $branch_id = $branch->id;

    {
        # create test
        my $test_name = 'some_test_name';
        my $test      = $schema->resultset('Test')->create(
            {
                name => $test_name,
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
        my $res = $http->request(
            'GET',
            "$host:$port/api/test?tags=all&branch_id=$branch_id",
        );
        is( $res->{status}, 200, 'get tests via api, response status 200' );
        my $tests = decode_json($res->{content});
        is(scalar @$tests, 1, '1 test found.');
        is($tests->[0]->{name}, 'some_test_name', 'correct test name');

        {
            sub get_jobs {
                my $res = $http->request(
                    'GET',
                    "$host:$port/api/job?filter=all",
                );
                is( $res->{status}, 200, 'get jobs via api, response status 200' );
                my $jobs = decode_json($res->{content});
                return $jobs;
            }
            my $jobs = get_jobs();
            is_deeply($jobs, [], 'no jobs exist yet.');

            # create job
            my $content_raw = encode_json( { test_id => $test->id, job_type => 'test' } );
            my $res = $http->request(
                'POST',
                "$host:$port/api/job",
                { content => $content_raw },
            );
            is( $res->{status}, 201, 'response status 201' );
            $jobs = get_jobs();
            is(scalar @$jobs, 1, 'one job exists.');

            # delete job
            $res = $http->request(
                'DELETE',
                "$host:$port/api/job/" . $jobs->[0]->{id},
            );
            $jobs = get_jobs();
            is(scalar @$jobs, 0, 'no jobs exist.');
        }

        $res = $http->request(
            'DELETE',
            "$host:$port/api/test/" . $test->id,
        );

        # test has been deleted via API, reload from DB
        $test->discard_changes;
        ok(!$test->in_storage, "test not in storage");
    }

    {
        # create tag
        my $schema    = EPPlication::Util::get_schema();
        my $tag_name = 'some_tag_name';
        my $tag_rs = $schema->resultset('Tag');
        my $cnt_before = $tag_rs->count;
        my $tag = $tag_rs->create( { name => $tag_name, color => '#aabbcc' } );
        ok( $tag, 'tag created' );
        my $res = $http->request(
            'GET',
            "$host:$port/api/tag",
        );
        is( $res->{status}, 200, 'response status 200' );
        my $tags = decode_json($res->{content});
        is(scalar @$tags, $cnt_before+1, 'tags found.');
        use List::Util qw/any/;
        my $found_tag = any {$_->{name} eq 'some_tag_name'} @$tags;
        ok( $found_tag, 'correct tag name' );
        $tag->delete;
        ok(!$tag->in_storage, "tag not in storage");
    }
};

done_testing();
