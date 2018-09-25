package EPPlication::Step::Multiline;

use Moose;
use EPPlication::Role::Step::Parameters;

with
  'EPPlication::Role::Step::Base',
  Parameters(parameter_list => [qw/ variable value global /]),
  ;

sub process {
    my ($self) = @_;

    my $global    = $self->global;
    my $variable  = $self->variable;

    $self->add_detail('Variable: ' . $variable);
    $self->add_detail('Global:   ' . $self->global);
    my $value = $self->process_tt_value( 'Value', $self->value, { between => ":\n" } );

    $self->stash_set( $variable, $value, $self->global );

    return $self->result;
}

__PACKAGE__->meta->make_immutable;
1;
