package EPPlication::Schema::Result::StepResult;
use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/ Core /);
__PACKAGE__->table('step_result');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'bigint',
        is_numeric        => 1,
        is_auto_increment => 1
    },
    job_id => {
        data_type      => 'int',
        is_numeric     => 1,
        is_foreign_key => 1,
    },
    test_id => {
        data_type   => 'int',
        is_numeric  => 1,
        is_nullable => 1,
    },
    step_id => {
        data_type   => 'int',
        is_numeric  => 1,
        is_nullable => 1,
    },
    node => {
        data_type   => 'varchar',
        is_nullable => 1, # root node == undef
    },
    details => {
        data_type   => 'varchar',
        is_nullable => 1,
    },
    node_position  => { data_type => 'int' },
    position       => { data_type => 'int' },
    name           => { data_type => 'varchar' },
    type           => { data_type => 'varchar' },
    status         => { data_type => 'varchar' },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->resultset_class('EPPlication::Schema::ResultSet::StepResult');

# inserting step_results requires a lookup
# of the position.
sub sqlt_deploy_hook {
    my ( $self, $sqlt_table ) = @_;
    $sqlt_table->add_index(
        name   => 'step_result_idx_job_id_node_position',
        fields => [ qw/ job_id node position / ],
    );
}

__PACKAGE__->belongs_to(
    'job',
    'EPPlication::Schema::Result::Job',
    'job_id',
);

1;
