package EPPlication::Schema::Result::Role;
use strict;
use warnings;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/ Core /);

__PACKAGE__->table('role');
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
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( [ qw/ name / ]  );

__PACKAGE__->has_many(
    'user_roles',
    'EPPlication::Schema::Result::UserRole',
    'role_id',
);

__PACKAGE__->many_to_many(
    'users',
    'user_roles',
    'user'
);

1;
