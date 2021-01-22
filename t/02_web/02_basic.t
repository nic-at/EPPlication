#!/usr/bin/env perl
use Dir::Self;
use lib __DIR__ . "/../lib";
use EPPlication::TestKit;
use Test::WWW::Mechanize::Catalyst;
use JSON::PP;

my $schema = EPPlication::Util::get_schema;

my $branch_name = 'master';
my $branch      = $schema->resultset('Branch')->single({name=>$branch_name});
my $branch_id   = $branch->id;

my $mech
    = Test::WWW::Mechanize::Catalyst->new( catalyst_app => 'EPPlication::Web' );
$mech->get_ok('/');
$mech->get_ok('/login');

# failing login
{
    my $login_data = {
        username => '__doesnotexist',
        password => '__doesnotexist',
    };
    $mech->submit_form_ok( { fields => $login_data },
        'Login attempt with invalid credentials' );
    $mech->content_contains(
        'Wrong username or password',
        'Invalid credentials error msg is present'
    );
}

# successful login
{
    my $login_data = {
        username => 'testuser',
        password => 'testpassword',
    };
    $mech->submit_form_ok( { fields => $login_data },
        'Login attempt with valid credentials' );
    my $logout_link = $mech->find_link( text => 'Logout (testuser)' );
    ok( $logout_link, 'Login successful. Found Logout link' );
}

# create tag
my $tag_name  = 'JustSomeTag';
my $tag_color = '#aabbcc';
my $tag_id;
{
    $mech->get_ok('/tag/create');
    $mech->submit_form_ok(
        {
            fields => {
                name  => $tag_name,
                color => $tag_color,
            },
        },
        'Create a tag'
    );
    $mech->content_lacks(
        'There were errors in your form',
        'No error message present'
    );
    $mech->content_contains("$tag_color\">$tag_name</span>");

    my $tag = $schema->resultset('Tag')->search( { name => $tag_name, color => '#aabbcc' })->single;
    ok( defined $tag, "Found tag with name '$tag_name' in DB" );
    $tag_id = $tag->id;
    my $tag_edit_link = $mech->find_link( url_regex => qr{/tag/$tag_id/edit} );
    ok(defined $tag_edit_link, 'tag edit link is present');
}

# create tests
my @tests = (
    {
        name => 'SomeTest',
    },
    {
        name => 'SomeOtherTest',
    }
);

{
    for my $test (@tests) {
        my $test_name = $test->{name};
        $mech->get_ok("/branch/$branch_id/test/create");
        $mech->submit_form_ok(
            {
                fields => {
                    name => $test_name,
                    tags => [$tag_id],
                },
            },
            "Create test $test_name."
        );
        $mech->content_lacks(
            'There were errors in your form',
            'No error message present'
        );

        my $t = $schema->resultset('Test')->search( { branch_id => $branch_id, name => $test_name })->single;
        ok( defined $t, "Found test with name '$test_name' in DB." );
        $test->{id} = $t->id;
        my $test_id = $t->id;

        $mech->base_like(
            qr{/branch/$branch_id/test/$test_id/show}xms,
            "we have been redirected to the test/$test_id/show page"
        );

        $mech->get_ok("/api/test?branch_id=$branch_id&tags=$tag_id&search=name%3A$test_name");
        my $json = decode_json($mech->content);
        is($json->[0]->{name}, $test_name, 'got correct test name');

        for my $action (qw/ show edit /) {
            my $link = "/branch/$branch_id/test/$test_id/$action";
            $mech->get_ok($link, "test $action link returns status 200");
        }
        for my $job_type (qw/ test temp /) {
            my $link = "/job/create/$job_type/$test_id";
            $mech->get_ok($link, "job create with type $job_type returns status 200");
        }
    }
}

# add steps
{
    my $test    = $tests[0];
    my $test_id = $test->{id};
    $mech->get_ok("/branch/$branch_id/test/$test_id/step/select");
    my @links = $mech->followable_links;
    @links = grep { $_->tag eq 'a' && $_->url !~ qr{(\/logout$|\/reports$)}xms } @links;
    $mech->links_ok( \@links, 'Check all links except /logout' );

    my @steps = (
        {
            type => 'Comment',
            parameters => {
                name    => 'SomeComment',
                comment => 'just some random comment',
            }
        },
        {
            type => 'DBConnect',
            parameters => {
                name => 'connect DB',
            }
        },
        {
            type => 'DB',
            parameters => {
                name       => 'send DB request',
                sql        => 'SELECT * FROM tag',
                var_result => 'db_response',
            }
        },
        {
            type => 'DBDisconnect',
            parameters => {
                name => 'disconnect DB',
            }
        },
        {
            type => 'EPPConnect',
            parameters => {
                name       => 'connect EPP',
                var_result => 'epp_response',
            }
        },
        {
            type       => 'EPP',
            parameters => {
                name         => 'send EPP frame',
                body         => '<xml>foo</xml>',
                var_result   => 'epp_response',
                validate_xml => 1,
              }
        },
        {
            type       => 'EPP',
            parameters => {
                name         => 'send invalid EPP frame',
                body         => 'asdf',
                var_result   => 'epp_response2',
                validate_xml => 0,
            }
        },
        {
            type => 'EPPDisconnect',
            parameters => {
                name => 'disconnect EPP',
            }
        },
        {
            type => 'CountQueryPath',
            parameters => {
                name       => 'count nodes in last EPP response',
                query_path => '/response/result/msg',
                var_result => 'epp_count',
                input      => '[% epp_response %]',
            }
        },
        {
            type => 'VarQueryPath',
            parameters => {
                name       => 'find data in last EPP response',
                query_path => '/response/result/msg',
                var_result => 'epp_count',
                input      => '[% epp_response %]',
            }
        },
        {
            type => 'SOAP',
            parameters => {
                method       => 'POST',
                name         => 'send SOAP frame',
                var_result   => 'soap_response',
                body         => '<xml>foo</xml>',
                validate_xml => 1,
            }
        },
        {
            type => 'CountQueryPath',
            parameters => {
                name       => 'count nodes in last SOAP response',
                query_path => '/response/result/msg',
                var_result => 'soap_count',
                input      => '[% soap_response %]',
            }
        },
        {
            type => 'VarQueryPath',
            parameters => {
                name       => 'find data in last SOAP response',
                query_path => '/response/result/msg',
                var_result => 'soap_count',
                input      => '[% soap_response %]',
            }
        },
        {
            type       => 'REST',
            parameters => {
                name          => 'send REST request',
                method        => 'GET',
                path          => '/registrar/dummy1',
                headers       => '{ "Content-Type":"application/json; charset=utf-8", "Accept": "application/json"}',
                body          => '{"username":"dümmy1"}', # using umlaut (use utf8; enabled in EPPlication::TestKit)
                var_result    => 'rest_response',
                var_status    => 'rest_status',
                check_success => 1,
                validate_json => 1,
            }
        },
        {
            type       => 'Whois',
            parameters => {
                name          => 'send Whois request',
                host          => 'whois.nic.at',
                port          => '43',
                domain        => 'epplication.at',
                var_result    => 'whois_response',
            }
        },
        {
            type => 'CountQueryPath',
            parameters => {
                name       => 'count nodes in last REST response',
                query_path => '/response/result/msg',
                var_result => 'rest_count',
                input      => '[% rest_response %]',
            }
        },
        {
            type => 'VarQueryPath',
            parameters => {
                name       => 'find data in last REST response',
                query_path => '/response/result/msg',
                var_result => 'rest_count',
                input      => '[% rest_response %]',
            }
        },
        {
            type => 'VarVal',
            parameters => {
                name     => 'set variable foo',
                variable => 'foo',
                value    => 'bar',
                global   => 1,
            }
        },
        {
            type => 'Math',
            parameters => {
                name     => 'multiply',
                variable => 'result_multiply',
                value_a  => '3',
                value_b  => '4',
                operator => '*',
            }
        },
        {
            type => 'Transformation',
            parameters => {
                name           => 'transformation Uppercase',
                input          => '[% foo %]',
                var_result     => 'foo_uc',
                transformation => 'Uppercase',
            }
        },
        {
            type => 'Transformation',
            parameters => {
                name           => 'transformation HeaderRow',
                input          => '{
                                    "headers": [ "h1", "h2", "h3" ],
                                    "rows":    [
                                                  [ "row_1_h1", "row_1_h2", "row_1_h3" ],
                                                  [ "row_2_h1", "row_2_h2", "row_2_h3" ]
                                               ]
                                  }',
                var_result     => 'foo_header_row',
                transformation => 'HeaderRow',
            }
        },
        {
            type => 'VarRand',
            parameters => {
                name     => 'set variable foo_rand to random value',
                variable => 'foo_rand',
                rand     => '\d{3}[A-Z]{3}[a-z]{3}',
            }
        },
        {
            type => 'VarCheck',
            parameters => {
                name     => 'check variable foo_uc has value "BAR"',
                variable => 'foo_uc',
                value    => 'BAR',
            }
        },
        {
            type       => 'VarCheckRegExp',
            parameters => {
                name      => 'match value against regexp',
                value     => '[% foo_uc %]',
                regexp    => '[a-zA-Z]+',
                modifiers => 'xms',
            }
        },
        {
            type => 'SubTest',
            parameters => {
                name       => 'execute subtest if condition is satisfied',
                condition  => '[% 1 == 1 %]',
                subtest_id => $tests[1]{id},
            }
        },
        {
            type => 'DataCmp',
            parameters => {
                name       => 'compare data structures',
                condition  => '1',
                'value_a' => '{ "foo":"1","bar":"2" }',
                'value_b' => '{ "bar":"2","foo":"1" }',
            }
        },
        {
            type => 'VarVal',
            parameters => {
                name       => 'set array',
                condition  => '1',
                variable   => 'var_array',
                value      => '["item_a","item_b","item_c"]',
            }
        },
        {
            type => 'ForLoop',
            parameters => {
                name       => 'execute subtest with each loop value',
                condition  => '1',
                variable   => 'loop_var',
                value      => 'loop_val_1,loop_val_2,loop_val_3',
                subtest_id => $tests[1]{id},
            }
        },
        {
            type => 'PrintVars',
            parameters => {
                name     => 'print stash content',
            }
        },
        {
            type => 'ClearVars',
            parameters => {
                name     => 'unset stash',
            }
        },
        {
            type       => 'DateAdd',
            parameters => {
                name     => 'add duration to date',
                variable => 'date_plus_duration',
                duration => '[% duration %]',
                date     => '[% date %]',
            }
        },
        {
            type       => 'DateCheck',
            parameters => {
                name => 'check if date_got is within date_expected +/- duration',
                date_got      => '[% date_plus_duration %]',
                duration      => '[% duration %]',
                date_expected => '[% date %]',
            }
        },
        {
            type       => 'DateFormat',
            parameters => {
                name            => 'add duration to date',
                variable        => 'formatted_date',
                date_format_str => '%d.%m.%Y',
                date            => '[% date %]',
            }
        },
        {
            type       => 'DateDiff',
            parameters => {
                name            => 'get diff between 2 dates',
                variable        => 'date_diff',
                date1           => '[% date1_str %]',
                date2           => '[% date2_str %]',
            }
        },
        {
            type => 'SSH',
            parameters => {
                name       => 'ls via SSH',
                var_stdout => 'ssh_stdout',
                ssh_host   => 'localhost',
                ssh_port   => 22,
                ssh_user   => 'epplication'.sprintf('%03d',int(rand(999))),
                command    => 'ls -lh',
            }
        },
        {
            type => 'Script',
            parameters => {
                name       => 'ls via Script',
                var_stdout => 'script_stdout',
                command    => 'ls -lh',
            }
        },
        {
            type => 'Multiline',
            parameters => {
                name     => 'set text1',
                variable => 'text1',
                value    => "Hello John\nBye",
            }
        },
        {
            type => 'Diff',
            parameters => {
                name     => 'diff',
                variable => 'diff1',
                value1   => '[%text1%]',
                value2   => "Hello John\nBye",
            }
        },
        {
            type       => 'SeleniumConnect',
            parameters => {
                name       => 'selenium connect',
                identifier => 'selenium_001',
                host       => 'localhost',
                port       => 4444,
            },
        },
        {
            type       => 'SeleniumRequest',
            parameters => {
                name       => 'selenium request',
                identifier => 'selenium_001',
                url        => 'http://epplication.at',
            },
        },
        {
            type       => 'SeleniumInput',
            parameters => {
                name       => 'selenium input',
                identifier => 'selenium_001',
                locator    => 'id',
                selector   => 'username',
                input      => 'admin',
            },
        },
        {
            type       => 'SeleniumClick',
            parameters => {
                name       => 'selenium click',
                identifier => 'selenium_001',
                locator    => 'xpath',
                selector   => q!//input[@id='submit']!,
            },
        },
        {
            type       => 'SeleniumContent',
            parameters => {
                name         => 'selenium body',
                identifier   => 'selenium_001',
                content_type => 'body_html',
                variable     => 'page_content',
            },
        },
        {
            type       => 'SeleniumJS',
            parameters => {
                name       => 'selenium js',
                identifier => 'selenium_001',
                javascript => 'console.log("foobar");',
            },
        },
        {
            type       => 'SeleniumDisconnect',
            parameters => {
                name       => 'selenium disconnect',
                identifier => 'selenium_001',
            },
        },
    );

    my $counter = 0;
    for my $step (@steps) {
        my $step_name = $step->{parameters}{name};
        my $step_type = $step->{type};
        $mech->get_ok("/branch/$branch_id/test/$test_id/step/create?type=$step_type&tags=$tag_id");
        $mech->submit_form_ok(
            {
                fields => $step->{parameters}
            },
            "Create a $step_type step"
        );
        $mech->base_like( qr{/branch/$branch_id/test/$test_id/show$},
            'redirected to test/show' );
        $mech->get_ok("/api/step?branch_id=$branch_id&test_id=$test_id", {'Content-Type' => 'application/json'});
        my $json = decode_json($mech->content);
        is($json->{steps}[$counter++]{name}, $step_name, 'API returned correct step');
    }
}

# attempt to add steps with wrong params
{
    my $test    = $tests[0];
    my $test_id = $test->{id};
    $mech->get_ok("/branch/$branch_id/test/$test_id/step/select");

    my @steps = (
        {
            type => 'VarVal',
            parameters => {
                name     => 'set variable foo',
                variable => 'a+++a',
                value    => 'bar',
                global   => 0,
            },
            expected_err_msg => '"a+++a" is not a valid variable name',
        },
        {
            type       => 'EPP',
            parameters => {
                name         => 'send invalid EPP frame again',
                body         => 'asdf',
                var_result   => 'epp_response2',
                validate_xml => 1,
            },
            expected_err_msg => 'Invalid XML',
        },
        {
            type       => 'SOAP',
            parameters => {
                name         => 'send invalid SOAP frame again',
                body         => 'soap_asdf',
                var_result   => 'soap_response2',
                validate_xml => 1,
            },
            expected_err_msg => 'Invalid XML',
        },
        {
            type       => 'REST',
            parameters => {
                name          => 'send REST request again',
                method        => 'GET',
                path          => '/registrar/dummy1',
                headers       => '{ "Content-Type":"application/json; charset=utf-8", "Accept": "application/json"}',
                body          => 'rest_asdf',
                var_result    => 'rest_response2',
                var_status    => 'rest_status2',
                check_success => 1,
                validate_json => 1,
            },
            expected_err_msg => 'Invalid JSON',
        },
    );

    for my $step (@steps) {
        my $step_name = $step->{parameters}{name};
        my $step_type = $step->{type};
        $mech->get_ok("/branch/$branch_id/test/$test_id/step/create?type=$step_type");
        $mech->submit_form_ok(
            {
                fields => $step->{parameters}
            },
            "Create a $step_type step"
        );
        $mech->base_like( qr{/branch/$branch_id/test/$test_id/step/create\?type=$step_type$},
            'redisplay step create page' );
        $mech->content_contains("There were errors in your form");
        $mech->content_contains( $step->{expected_err_msg} );
    }
}

# clone test
{
    my $test_name = $tests[0]->{name};
    my $t = $schema->resultset('Test')->search({ branch_id => $branch_id, name => $test_name })->single;
    ok( defined $t, "Found test with name '$test_name' in DB." );
    my $test_id = $t->id;
    $mech->post_ok("/api/test/clone", {test_id => $test_id});
}

# clone branch
{
    my $count_before = $schema->resultset('Test')->count;
    ok($count_before > 1, "more then 1 tests exist before branch cloning.");
    $mech->get_ok('/branch/list');
    my $form_id = 'form_' . $branch_id . '_clone';
    $mech->submit_form( form_id => $form_id );
    $mech->content_contains(
        "Branch $branch_name cloned successfully.",
        'branch clone success msg found'
    );
    $mech->content_contains(
        "$branch_name (CLONE)",
        'branch clone name found in list'
    );
    my $count_after = $schema->resultset('Test')->count;
    ok($count_after == $count_before*2, "after branch cloning two times as many tests exist.");
}

# delete cloned branch
{
    my $count_before = $schema->resultset('Test')->count;
    ok($count_before > 1, "more then 1 tests exist before branch clone deletion.");
    my $clone = $schema->resultset('Branch')->single({name=>"$branch_name (CLONE)"});
    my $clone_id = $clone->id;
    my $form_id = 'form_' . $clone_id . '_delete';
    $mech->submit_form( form_id => $form_id );
    $mech->content_contains(
        "$branch_name (CLONE) deleted.",
        'branch delete success msg found'
    );
    my $count_after = $schema->resultset('Test')->count;
    ok($count_after*2 == $count_before, "after branch deletion half as many tests exist.");
}

# delete jobs
$schema->resultset('Job')->delete;

# delete tests
$schema->resultset('Test')->delete;

# delete tag
{
    $mech->get_ok('/tag/list');
    my $form_id = 'form_' . $tag_id . '_delete';
    $mech->submit_form( form_id => $form_id );
    $mech->content_contains(
        "$tag_name deleted.",
        'Tag delete success msg found'
    );
}

# logout
{
    $mech->get_ok('/logout');
    my $login_link = $mech->find_link( text => 'Login' );
    ok( $login_link, 'Logout successful. Found Login link' );
}

done_testing();
