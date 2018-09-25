#!/usr/bin/env perl
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use EPPlication::TestKit;

my $schema = EPPlication::Util::get_schema();

my $branch = $schema->resultset('Branch')->single({name=>'master'});

my $tag = $schema->resultset('Tag')->create( { name => '__test_tag' } );
ok( $tag, "test tag created." );

my $test1 = create_test('test1');
my $test2 = create_test('test2');
my $test3 = create_test('test3');
my $test4 = create_test('test4');

# test1 [ > test1 ] = OK
is_loop($test1, $test1);

# test1 [ > test2 ] = NOTOK
isnt_loop($test1, $test2);

diag("test1 > test2");
make_subtest( $test1, $test2 );
my $step1 = $test1->steps->first;
is( $step1->parameters->{subtest_id}, $test2->id, "test2 is subtest of test1" );
is( 1, $test1->subtests->count, "test1 has 1 subtest" );

# test1 > test2 [ > test1 ] = NOTOK
is_loop($test2, $test1);

diag("test1 > test2 > test3");
make_subtest( $test2, $test3 );

# test1 > test2 > test3 [ > test1 ] = NOTOK
is_loop($test3, $test1);

# test1 > test2 > test3 [ > test1 ] = NOTOK
is_loop($test3, $test1);

# test1 > test2 > test3 [ > test2 ] = NOTOK
is_loop($test3, $test2);

# test1 > test2 > test3
#     [ > test2 ]       = OK
isnt_loop($test1, $test2);

diag("test1 > test2 > test3");
diag("      > test4");
make_subtest( $test1, $test4 );

# test1 > test2 > test3
#       > test4 [ > test3 ] = OK
isnt_loop($test4, $test3);

diag("test1 > test2 > test3");
diag("      > test4 > test3");
make_subtest( $test4, $test3 );
ok( !$test1->has_circular_ref, "test1 does not have a loop." );

$test1->delete;
$test2->delete;
$test3->delete;
$test4->delete;
$tag->delete;

done_testing();

sub create_test {
    my $name = shift;
    my $test = $schema->resultset('Test')->create( { branch => $branch, name => $name } );
    ok( $test, "test '$name' created (" . $test->id . ")" );
    $test->add_to_tags($tag);
    return $test;
}

sub make_subtest {
    my ( $parent, $child ) = @_;
    $parent->steps->create(
        {
            name       => 'subtest',
            type       => 'SubTest',
            parameters => { subtest_id => $child->id },
        }
    );
}
sub is_loop {
    my ($parent, $child) = @_;
    ok(
        $parent->causes_circular_ref( $child->id ),
        'adding '.$child->name.' as subtest of '.$parent->name.' causes a loop'
    );
}
sub isnt_loop {
    my ($parent, $child) = @_;
    ok(
        !$parent->causes_circular_ref( $child->id ),
        'adding '.$child->name.' as subtest of '.$parent->name.' does not cause a loop'
    );
}
