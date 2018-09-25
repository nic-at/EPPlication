package EPPlication::Schema::Result::UserRole;
use strict;
use warnings;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/ Core /);
__PACKAGE__->table('user_role');
__PACKAGE__->add_columns(
    'id',
    {
        data_type => 'integer',
        is_auto_increment => 1,
        is_numeric => 1,
    },
    'user_id',
    {
        data_type => 'integer',
        is_numeric => 1,
        is_foreign_key => 1,
    },
    'role_id',
    {
        data_type => 'integer',
        is_numeric => 1,
        is_foreign_key => 1,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( [qw/user_id role_id/] );

__PACKAGE__->belongs_to(
    'user',
    'EPPlication::Schema::Result::User',
    'user_id'
);

__PACKAGE__->belongs_to(
    'role',
    'EPPlication::Schema::Result::Role',
    'role_id'
);

1;
