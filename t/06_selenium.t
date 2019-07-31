#!/usr/bin/env perl
use Dir::Self;
use lib __DIR__ . "/lib";
use EPPlication::TestKit;

SKIP: {
    skip(
        'set EPPLICATION_TESTSELENIUM=1 EPPLICATION_TESTSELENIUM_HOST=epplication-selenium EPPLICATION_TESTSELENIUM_PORT=4444 to run Selenium Steptests.',
        1
    )
      unless ( defined $ENV{EPPLICATION_TESTSELENIUM}
          && defined $ENV{EPPLICATION_TESTSELENIUM_HOST}
          && defined $ENV{EPPLICATION_TESTSELENIUM_PORT} );

    my $schema = EPPlication::Util::get_schema();
    my $username = 'seleniumuser';
    my $password = 'seleniumpassword';
    my $sel_user   = EPPlication::Util::create_user($username, $password);
    diag "Created user 'selenium user'.";
    ok($sel_user, "User 'selenium user' created.");

    my $branch = $schema->resultset('Branch')->single({name=>'master'});
    my $test = $schema->resultset('Test')->create({branch=>$branch,name=>'test'});
    ok($test, "test created");
    my $user = $schema->resultset('User')->first;
    my @steps = (
        {
            type       => 'SeleniumConnect',
            name       => 'selenium connect',
            parameters => {
                identifier => 'selenium_001',
                host       => $ENV{EPPLICATION_TESTSELENIUM_HOST},
                port       => $ENV{EPPLICATION_TESTSELENIUM_PORT},
            },
        },
        {
            type       => 'SeleniumRequest',
            name       => 'selenium request',
            parameters => {
                identifier => 'selenium_001',
                url        => 'http://epplication-app/login',
            },
        },
        {
            type       => 'SeleniumInput',
            name       => 'selenium input',
            parameters => {
                identifier => 'selenium_001',
                locator    => 'id',
                selector   => 'username',
                input      => $username,
            },
        },
        {
            type       => 'SeleniumInput',
            name       => 'selenium input',
            parameters => {
                identifier => 'selenium_001',
                locator    => 'xpath',
                selector   => q!//input[@id='password']!,
                input      => $password,
            },
        },
        {
            type       => 'SeleniumClick',
            name       => 'selenium click',
            parameters => {
                identifier => 'selenium_001',
                locator    => 'xpath',
                selector   => q!//input[@id='submit']!,
            },
        },
        {
            type       => 'SeleniumContent',
            name       => 'selenium content',
            parameters => {
                identifier   => 'selenium_001',
                variable     => 'page_title',
                content_type => 'title',
            },
        },
        {
            type       => 'VarCheckRegExp',
            name       => 'regexp1',
            parameters => {
                regexp  => 'EPPlication',
                value   => '[% page_title %]',
                modifiers => 'xms',
            },
        },
        {
            type       => 'SeleniumJS',
            name       => 'selenium js',
            parameters => {
                identifier => 'selenium_001',
                javascript => 'console.log("foobar");',
            },
        },
        {
            type       => 'SeleniumDisconnect',
            name       => 'selenium disconnect',
            parameters => {
                identifier => 'selenium_001',
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

    my $stats    = $job->run($test_env);
    ok(!exists $stats->{errors}, 'no errors');
    my $num_steps = scalar(@steps);
    $num_steps += 2; # +1 for root node (1), +1 for test root node (1.1)
    is($stats->{num_steps}, $num_steps, 'num_steps is correct');

    for my $result ($job->step_results->default_order->all) {
        diag $result->name . ":\n" . $result->details if $result->status eq 'error';
        if ( $result->type eq 'VarCheckRegExp' ) {
            is($result->status, "success", "Step '" . $result->name. "' result status is 'success'");
        }
        else {
            is($result->status, "ok", "Step '" . $result->name. "' result status is 'ok'");
        }
    }

    $test->delete;
    ok(!$test->in_storage, "test not in storage");
    $job->delete;
    ok(!$job->in_storage, "job not in storage");
    $sel_user->delete;
    ok(!$sel_user->in_storage, "selenium user not in storage");
}

done_testing();
