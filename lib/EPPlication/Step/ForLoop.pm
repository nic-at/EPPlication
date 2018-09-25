package EPPlication::Step::ForLoop;
use Moose;
use EPPlication::Role::Step::Parameters;
with
  'EPPlication::Role::Step::SubTest',
  Parameters( parameter_list => [qw/ variable values /] ),
  'EPPlication::Role::Step::Util::Encode',
  ;

sub process {
    my ($self) = @_;

    my $subtest    = $self->get_subtest();
    my $subtest_id = $subtest->id;

    my $variable   = $self->variable;
    $self->add_detail("Variable: $variable");

    my $values_json = $self->process_tt_value( 'Values', $self->values );
    my $values = $self->json2pl($values_json);

    my @subtest_steps = ();
    my $position      = 1;
    my $iteration     = 1;
    for my $value ( @$values ) {

        $value = $self->pl2json($value)
          if ( ref $value eq 'HASH' || ref $value eq 'ARRAY' );

        my $step_rs = $self->tests->result_source->schema->resultset('Step');
        my $varval_step = $step_rs->new_result(
            {
                type          => 'VarVal',
                name          => "Set $variable",
                position      => $position++,
                parameters    => { variable => $variable, value => $value, global => 0 },
            },
        );
        my $subtest_step = $step_rs->new_result(
            {
                type          => 'SubTest',
                name          => 'Iteration #' . $iteration++,
                position      => $position++,
                parameters    => { subtest_id => $subtest_id },
            },
        );

        push(@subtest_steps, $varval_step, $subtest_step);
    }

    $self->add_subtest_steps(
        map {
            { $_->get_inflated_columns }
        } @subtest_steps
    );

    return $self->result;
}

__PACKAGE__->meta->make_immutable;
1;
