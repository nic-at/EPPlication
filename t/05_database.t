#!/usr/bin/env perl
use Dir::Self;
use lib __DIR__ . "/lib";
use EPPlication::TestKit;
use File::Temp qw/ tmpnam /;

my $schema = EPPlication::Util::get_schema();
my $branch = $schema->resultset('Branch')->single({name=>'master'});
my $tag = $schema->resultset('Tag')->create( { name => '__test_tag' } );
ok( $tag, "test tag created." );

my $num_tests = 4;
my %tests = ();
$tests{"test_$_"} = create_test("test_$_") for 1 .. $num_tests;

is( _num_tests(), $num_tests, "we have $num_tests tests." );

my $dbscript_path = __DIR__ . "/../script/database.pl";
{
    my $res = qx/$dbscript_path --cmd version/;
    diag $res;
    like(
        $res,
        qr/schema\ version:\s+\d+.*database\ version:\s+\d+/s,
        'get app+db version'
    );
}

{
    my $res;
    my $filename = tmpnam();

    # dump-tests
    $res = qx/$dbscript_path --cmd dump-tests --file $filename/;
    diag $res;
    ok( -f $filename, "file $filename is a plain file." );
    ok( -s $filename, "$filename has non-zero size." );

    # delete-tests
    $res = qx/$dbscript_path --cmd delete-tests/;
    diag $res;
    is(_num_tests(), 0, "we have 0 tests." );

    # restore-tests
    $res = qx/$dbscript_path --cmd restore-tests --file $filename/;
    diag $res;
    is(_num_tests(), $num_tests, "we have 0 tests." );

    is(1, unlink($filename), "dump file $filename has been deleted.");
}

{
    # branch
    my $res = qx/$dbscript_path --cmd branch --src-branch master --dest-branch devel/;
    diag $res;
    is(_num_tests(), 2*$num_tests, "we have twice as many tests after branching." );
    my $master = $schema->resultset('Branch')->find('master', {key=>'branch_name'});
    my $devel = $schema->resultset('Branch')->find('devel', {key=>'branch_name'});
    is($devel->tests->count(), $num_tests, "deval branch has $num_tests tests." );
    $devel->delete;
    is(_num_tests(), $num_tests, "we have $num_tests again after branch was deleted." );
}

{
    # delete-jobs
    create_job();
    my $num_jobs = _num_jobs();
    ok($num_jobs >=1, 'we have at least 1 job');
    my $res = qx/$dbscript_path --cmd delete-jobs/;
    diag $res;
    is(_num_jobs(), 0, "0 jobs in DB" );
}

$tests{"test_$_"}->delete for 1 .. $num_tests;
$tag->delete;

done_testing();

sub _num_tests {
    return $schema->resultset('Test')->count();
}
sub _num_jobs {
    return $schema->resultset('Job')->count();
}

sub create_job {
    my $test = $tests{"test_1"};
    my $user = $schema->resultset('User')->first;
    my $job = $schema->resultset('Job')->create(
        {
            test_id   => $test->id,
            type      => 'test',
            user_id   => $user->id,
        }
    );
    ok($job, "job created");
}

sub create_test {
    my $name = shift;
    my $test = $schema->resultset('Test')->create( { branch => $branch, name => $name } );
    ok( $test, "test '$name' created (" . $test->id . ")" );
    $test->add_to_tags($tag);
    return $test;
}
