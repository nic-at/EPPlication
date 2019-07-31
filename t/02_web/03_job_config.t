#!/usr/bin/env perl
use Dir::Self;
use lib __DIR__ . "/../lib";
use EPPlication::TestKit;
use Test::WWW::Mechanize::Catalyst;

my $schema = EPPlication::Util::get_schema();

my $branch    = $schema->resultset('Branch')->single({name=>'master'});
my $branch_id = $branch->id;

my $mech = Test::WWW::Mechanize::Catalyst->new( catalyst_app => 'EPPlication::Web' );
$mech->get_ok('/login');

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

# test data
my $test   = { name => 'my-test' };
# config data
my $config = { name => 'my-config' };

my $config_tag = $schema->resultset('Tag')->search({ name => 'config' })->single;
ok ($config_tag, "found 'config' tag.");

$mech->get_ok("/branch/$branch_id/test/create");
$mech->submit_form_ok(
    {
        fields => {
            name => $config->{name},
            tags => [$config_tag->id],
        },
    },
    'Create config ' . $config->{name}
);
$mech->content_lacks( 'There were errors in your form', 'No error message present' );
$mech->base_like( qr{/branch/$branch_id/test/\d+/show}xms, 'we have been redirected to the test/show page' );

$mech->get_ok("/branch/$branch_id/test/create");
$mech->submit_form_ok(
    {
        fields => {
            name => $test->{name},
        },
    },
    'Create test ' . $test->{name}
);
$mech->content_lacks( 'There were errors in your form', 'No error message present' );
$mech->base_like( qr{/branch/$branch_id/test/\d+/show}xms, 'we have been redirected to the test/show page' );

my $config_from_schema = $schema->resultset('Test')->search( { branch_id => $branch_id, name => $config->{name} })->single;
ok( defined $config_from_schema, "Found test with name '" . $config->{name} . "' in DB" );
$config->{id} = $config_from_schema->id;
my $config_id = $config_from_schema->id;

my $test_from_schema = $schema->resultset('Test')->search( { branch_id => $branch_id, name => $test->{name} })->single;
ok( defined $test_from_schema, "Found test with name '" . $test->{name} . "' in DB" );
$test->{id} = $test_from_schema->id;
my $test_id = $test_from_schema->id;

my $comment = 'foo--bar--baz';
my $step = $config_from_schema->steps->create(
    {
        type       => 'Comment',
        name       => 'just a comment',
        parameters => { comment => $comment },
    }
);
ok($step, 'step has been created');

# check if new test appears in Config pulldown menu
$mech->content_lacks( '/clear_config', 'clear_config link not present because no config has been activated' );
$mech->content_contains( "/branch/$branch_id/test/$config_id/select_config", 'new test appears in config pulldown menu' );

# activate config
$mech->follow_link_ok(
    { url_regex => qr{/branch/$branch_id/test/$config_id/select_config} },
    'activate config'
);
$mech->content_contains( '/clear_config', 'clear_config link present after config has been activated' );

# run a test
my $req = HTTP::Request->new( 'POST', '/api/job' );
$req->header( 'Content-Type' => 'application/json' );
$req->content( qq/{"test_id":"$test_id", "job_type":"test", "config_id":"$config_id"}/ );

$mech->request($req);
is($mech->status, 201, 'status is 201');
my $location = $mech->res->header('location');
is($location, 'http://localhost/job/list', 'found location to job list.');

my $job = $schema->resultset('Job')->first;
ok($job, 'job was created');
is( $job->config->name, $config->{name}, 'job has config.' );
is( $job->test->name, $test->{name}, 'job has test.' );

# run job, usually a job daemon would do this
my $test_env = EPPlication::Util::get_test_env();
my $stats = $job->run($test_env);

ok(!$stats->{errors}, 'no errors');

# get node, usually requested by browser via ajax
$mech->add_header( Accept => 'application/json' );
$mech->get_ok("/api/job/load_node?job_id=" . $job->id . "&node_id=1");
my $config_from_schema_name = $config_from_schema->name;
$mech->content_like(
    qr{SubTest\ -\ my-test}xms,
    "found config name($config_from_schema_name) in content."
);

# search node
{
    my $pos = 1;
    $mech->get_ok("/job/" . $job->id . "/show?search=position%3A$pos");
    $mech->content_contains( '<a href="" class="quicklink-init btn btn-xs btn-default" data-path="1">root</a>' );
}

# delete job
$job->delete;

# delete tests
$schema->resultset('Test')->delete;

# logout
{
    $mech->get_ok('/logout');
    my $login_link = $mech->find_link( text => 'Login' );
    ok( $login_link, 'Logout successful. Found Login link' );
}

done_testing();
