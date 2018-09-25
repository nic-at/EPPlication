package EPPlication::Schema::Result::Tag;
use strict;
use warnings;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/ Core /);
__PACKAGE__->table('tag');
__PACKAGE__->add_columns(
    'id',
    {
        data_type => 'integer',
        is_auto_increment => 1,
        is_numeric => 1,
    },
    'name',
    {
        data_type => 'varchar',
    },
    'color',
    {
        data_type     => 'varchar',
        default_value => '#ffffff',
    },
);

__PACKAGE__->resultset_class('EPPlication::Schema::ResultSet::Tag');
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( [ qw/ name / ]  );

__PACKAGE__->has_many(
    'test_tags',
    'EPPlication::Schema::Result::TestTag',
    'tag_id',
);

__PACKAGE__->many_to_many(
    'tests',
    'test_tags',
    'test'
);

1;
