package EPPlication::Web::Role::Form::Step::SubTest;
use HTML::FormHandler::Moose::Role;
use namespace::autoclean;

has 'tests_rs' => (
    isa      => 'DBIx::Class::ResultSet',
    is       => 'ro',
    required => 1,
);
has_field 'subtest_id' => (
    label        => 'Subtest',
    type         => 'Select',
    required     => 1,
    noupdate     => 1,
    no_option_validation => 1,
    options => [],
);
sub validate_subtest_id {
    my ( $self, $field ) = @_;
    my $subtest_id = $field->value;
    my $subtest    = $self->tests_rs->find($subtest_id);

    if (!defined $subtest) {
        $field->push_errors("subtest_id $subtest_id does not exist");
        return;
    }
    my $test = $self->item->test;
    if ($test->causes_circular_ref($subtest->id)) {
        $field->push_errors( 'Adding subtest "'
          . $subtest->name . '" to "'
          . $test->name
          . '" would cause a circular reference.' );
        return;
    }
}
# when editing a subtest step we need the current subtest_id so
# we can set the current value in the select via javascript
has_field 'hidden_subtest_id' => (
    type     => 'Hidden',
    noupdate => 1,
    inactive => 1,
);
sub default_hidden_subtest_id {
    my $self = shift;
    my $item = $self->item;
    return unless $item;
    my $parameters = $item->parameters;
    return unless $parameters;
    return $parameters->{subtest_id};
}

around '_build_parameter_fields' => sub {
    my ($orig, $self) = @_;
    return [ @{ $self->$orig }, 'subtest_id' ];
};

1;
