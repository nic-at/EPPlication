package EPPlication::Step::Transformation;

use Moose;
use EPPlication::Role::Step::Parameters;

with
  'EPPlication::Role::Step::Base',
  Parameters(parameter_list => [qw/ input var_result transformation /]),
  'EPPlication::Role::Step::Util::Encode',
  ;

has 'transformation_factory' => (
    is  => 'ro',
    isa => 'EPPlication::Step::Transformation::Factory',
);

sub process {
    my ($self) = @_;

    my $transformation = $self->transformation;
    $self->add_detail("type: $transformation");
    my $var_result     = $self->var_result;
    my $input          = $self->process_tt_value( 'input', $self->input, { show_diff => 0 } );

    my $transformer = $self->transformation_factory->create($transformation);
    $transformer->transform($self, $var_result, $input);

    return $self->result;
}


__PACKAGE__->meta->make_immutable;
1;
