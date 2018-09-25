#!/usr/bin/env perl
use FindBin qw/$Bin/;
use lib "$Bin/lib";
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

my $dbscript_path = "$Bin/../script/database.pl";
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

$tests{"test_$_"}->delete for 1 .. $num_tests;
$tag->delete;

done_testing();

sub _num_tests {
    return $schema->resultset('Test')->count();
}

sub create_test {
    my $name = shift;
    my $test = $schema->resultset('Test')->create( { branch => $branch, name => $name } );
    ok( $test, "test '$name' created (" . $test->id . ")" );
    $test->add_to_tags($tag);
    return $test;
}
