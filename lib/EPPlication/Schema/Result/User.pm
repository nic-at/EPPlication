package EPPlication::Schema::Result::User;
use strict;
use warnings;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/ PassphraseColumn Core /);
__PACKAGE__->table('user');
__PACKAGE__->add_columns(
    id => {
        data_type => 'int',
        is_numeric => 1,
        is_auto_increment => 1
    },
    name => {
        data_type => 'varchar',
    },
    password => {
        data_type           => 'text',
        passphrase          => 'rfc2307',
        passphrase_class    => 'BlowfishCrypt',
        passphrase_args     => {
            cost        => 8,
            salt_random => 20,
        },
        passphrase_check_method => 'check_password',
    },
);

__PACKAGE__->set_primary_key ('id');
__PACKAGE__->add_unique_constraint( [ qw/ name / ]  );
__PACKAGE__->resultset_class('EPPlication::Schema::ResultSet::User');

__PACKAGE__->has_many(
    'user_roles',
    'EPPlication::Schema::Result::UserRole',
    'user_id',
);

__PACKAGE__->many_to_many(
    'roles',
    'user_roles',
    'role'
);

__PACKAGE__->has_many(
    'jobs',
    'EPPlication::Schema::Result::Job',
    'user_id',
    { cascade_copy => 0, cascade_delete => 0 },
);

1;
