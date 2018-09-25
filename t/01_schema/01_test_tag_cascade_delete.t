#!/usr/bin/env perl
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use EPPlication::TestKit;

my $schema = EPPlication::Util::get_schema();

my $branch = $schema->resultset('Branch')->single({name=>'master'});

my $tag = $schema->resultset('Tag')->create({name=>'__test_tag'});
ok($tag, "test tag created.");

my $test1 = $schema->resultset('Test')->create({branch=>$branch,name=>'__test1'});
ok($test1, "test1 created");

my $test2 = $schema->resultset('Test')->create({branch=>$branch,name=>'__test2'});
ok($test2, "test2 created");

$test1->add_to_tags($tag);
$test2->add_to_tags($tag);
my $_tag = $test1->tags->first;
ok($_tag, "test1 has tag.");
is($tag->id, $_tag->id, "test1->tag and tag are identical.");

$test1->delete;
ok(!$test1->in_storage, "test1 not in storage");
$test2->delete;
ok(!$test2->in_storage, "test2 not in storage");
$tag->delete;
ok(!$tag->in_storage, "tag not in storage");

done_testing();
