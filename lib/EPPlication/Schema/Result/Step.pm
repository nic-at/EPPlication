package EPPlication::Schema::Result::Step;
use strict;
use warnings;
use base qw/DBIx::Class/;
use List::Util qw/ any /;

__PACKAGE__->load_components(qw/ InflateColumn::Serializer Ordered Core /);
__PACKAGE__->table('step');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_numeric        => 1,
        is_auto_increment => 1
    },
    name     => { data_type => 'varchar' },
    position => { data_type => 'int' },
    active   => {
        data_type     => 'boolean',
        default_value => 1,
    },
    highlight => {
        data_type     => 'boolean',
        default_value => 0,
    },
    condition   => {
        data_type     => 'varchar',
        default_value => '1',
    },
    test_id  => {
        data_type      => 'int',
        is_numeric     => 1,
        is_foreign_key => 1,
    },
    type       => { data_type => 'varchar', },
    parameters => {
        data_type        => 'varchar',
        is_nullable      => 1,
        serializer_class => 'JSON',
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->grouping_column('test_id');
__PACKAGE__->position_column('position');
__PACKAGE__->resultset_class('EPPlication::Schema::ResultSet::Step');

# EPPlication::Schema::Result::Test is looking up
# steps by type 'SubTest'
sub sqlt_deploy_hook {
    my ( $self, $sqlt_table ) = @_;
    $sqlt_table->add_index( name => 'step_idx_type', fields => ['type'] );
}

# wait for bugfix in DBIx::Class::Ordered
#__PACKAGE__->add_unique_constraint([ qw/ test_id position / ]);

__PACKAGE__->belongs_to(
    'test',
    'EPPlication::Schema::Result::Test',
    'test_id',
);

sub has_subtest {
    my ($self) = @_;
    my $schema = $self->result_source->schema;
    return any { $self->type eq $_ } @{ $schema->subtest_types };
}

sub subtest {
    my ($self) = @_;

    my $schema = $self->result_source->schema;
    my $subtest = $schema->resultset('Test')->find(
        $self->parameters->{subtest_id}
    );

    return $subtest;
}

1;
