package EPPlication::Schema::Result::Branch;
use strict;
use warnings;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/ Core /);
__PACKAGE__->table('branch');
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

__PACKAGE__->resultset_class('EPPlication::Schema::ResultSet::Branch');
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( [ qw/ name / ]  );

__PACKAGE__->has_many(
    'tests',
    'EPPlication::Schema::Result::Test',
    'branch_id',
);

# copy selected branch including all all tests and steps.
# this operation can take some time.
sub clone {
    my ( $self, $new_branchname ) = @_;
    my @clones  = ();
    my %mapping = (); # for fixing subtest relationship
    my $schema  = $self->result_source->schema;
    $schema->txn_do(
        sub {
            my $new_branch = $schema->resultset('Branch')->create({ name => $new_branchname });
            my $test_rs = $self->tests;
            while (my $orig = $test_rs->next) {
                my $clone = $orig->copy({ branch_id => $new_branch->id });
                $mapping{ $orig->id } = $clone->id;
                push(@clones,$clone);
            }

            for my $clone (@clones) {
                my $subtest_steps = $clone->subtest_steps;
                while ( my $subtest_step = $subtest_steps->next ) {
                    my $parameters = $subtest_step->parameters;
                    my $new_id = $mapping{ $parameters->{subtest_id} };
                    die "Couldnt find mapping id for step " . $subtest_step->id
                        unless defined $new_id;
                    $parameters->{subtest_id} = $new_id;
                    $subtest_step->update({parameters => $parameters});
                }
            }
        }
    );
}

1;
