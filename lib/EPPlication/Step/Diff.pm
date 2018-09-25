package EPPlication::Step::Diff;

use Moose;
use EPPlication::Role::Step::Parameters;
use Text::Diff;

with
  'EPPlication::Role::Step::Base',
  Parameters(parameter_list => [qw/ variable value1 value2 /]),
  ;

sub process {
    my ($self) = @_;

    my $variable = $self->variable;
    $self->add_detail('Variable: ' . $variable);
    my $value1 = $self->process_tt_value('Value1', $self->value1, { between => ":\n", after => "\n" });
    my $value2 = $self->process_tt_value('Value2', $self->value2, { between => ":\n", after => "\n" });

    my $diff = diff( \$value1, \$value2 );
    $self->add_detail("Diff:\n$diff");
    $self->stash_set( $variable, $diff );

    return $self->result;
}

__PACKAGE__->meta->make_immutable;
1;
