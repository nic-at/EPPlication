package EPPlication::Step::VarRand;

use Moose;
use EPPlication::Role::Step::Parameters;
use EPPlication::String::Random qw/ rand_regex /;

with
  'EPPlication::Role::Step::Base',
  Parameters(parameter_list => [qw/ variable rand /]),
  ;

sub process {
    my ($self) = @_;

    my $variable = $self->variable;
    $self->add_detail('Variable: ' . $variable);

    my $rand = $self->process_tt_value( 'Pattern', $self->rand );

    my $value = rand_regex($rand);
    $self->stash_set( $variable => $value );
    $self->add_detail('Value: ' . $value);

    return $self->result;
}

__PACKAGE__->meta->make_immutable;
1;
