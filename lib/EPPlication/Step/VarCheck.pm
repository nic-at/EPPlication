package EPPlication::Step::VarCheck;

use Moose;
use EPPlication::Role::Step::Parameters;

with
  'EPPlication::Role::Step::Base',
  Parameters(parameter_list => [qw/ variable value /]),
  ;

sub process {
    my ($self) = @_;

    my $variable  = $self->variable;

    $self->add_detail("Variable: $variable");
    die "$variable not found in stash.\n"
      if ( !$self->stash_exists($variable)
        || !$self->stash_defined($variable) );

    my $value = $self->process_tt_value( 'Value', $self->value );

    my $value_got = $self->stash_get($variable);
    die "expected:\n$value\n"
      . "got:\n$value_got\n"
        if $value_got ne $value;

    $self->status('success');

    return $self->result;
}

__PACKAGE__->meta->make_immutable;
1;
