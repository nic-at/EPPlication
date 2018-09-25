package EPPlication::Schema::Result::TestTag;
use strict;
use warnings;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/ Core /);
__PACKAGE__->table('test_tag');
__PACKAGE__->add_columns(
    'id',
    {
        data_type => 'integer',
        is_auto_increment => 1,
        is_numeric => 1,
    },
    'test_id',
    {
        data_type => 'integer',
        is_numeric => 1,
        is_foreign_key => 1,
    },
    'tag_id',
    {
        data_type => 'integer',
        is_numeric => 1,
        is_foreign_key => 1,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( [qw/test_id tag_id/] );

__PACKAGE__->belongs_to(
    'test',
    'EPPlication::Schema::Result::Test',
    'test_id'
);

__PACKAGE__->belongs_to(
    'tag',
    'EPPlication::Schema::Result::Tag',
    'tag_id'
);

1;
