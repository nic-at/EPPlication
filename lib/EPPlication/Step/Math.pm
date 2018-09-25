package EPPlication::Step::Math;

use Moose;
use EPPlication::Role::Step::Parameters;

with
  'EPPlication::Role::Step::Base',
  Parameters(parameter_list => [qw/ variable value_a value_b operator /]),
  ;

sub process {
    my ($self) = @_;

    my $variable    = $self->variable;
    my $operator    = $self->operator;

    $self->add_detail( "Variable: $variable" );
    $self->add_detail( "Operator: $operator" );
    my $value_a = $self->process_tt_value( 'Value_a', $self->value_a );
    my $value_b = $self->process_tt_value( 'Value_b', $self->value_b );

    my $result;
    if    ( $operator eq '+' )  { $result = $value_a + $value_b; }
    elsif ( $operator eq '-' )  { $result = $value_a - $value_b; }
    elsif ( $operator eq '*' )  { $result = $value_a * $value_b; }
    elsif ( $operator eq '/' )  { $result = $value_a / $value_b; }
    elsif ( $operator eq '&&' ) { $result = $value_a && $value_b; }
    elsif ( $operator eq '||' ) { $result = $value_a || $value_b; }
    else { die "Unknown operator. ($operator)\n"; }

    $self->add_detail( $result );
    $self->stash_set( $variable => $result );

    return $self->result;
}

__PACKAGE__->meta->make_immutable;
1;
