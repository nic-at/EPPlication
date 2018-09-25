package EPPlication::Step::DataCmp;

use Moose;
use EPPlication::Role::Step::Parameters;
use Data::Compare qw//;

with
  'EPPlication::Role::Step::Base',
  'EPPlication::Role::Step::Util::Encode',
  Parameters( parameter_list => [qw/ value_a value_b /] ),
  ;

sub process {
    my ($self) = @_;

    my $value_a = $self->process_tt_value( 'Value_a', $self->value_a );
    my $value_b = $self->process_tt_value( 'Value_b', $self->value_b );

    my $value_a_pl = $self->json2pl($value_a);
    my $value_b_pl = $self->json2pl($value_b);

    if ( !Data::Compare::Compare( $value_a_pl, $value_b_pl ) ) {
        die "value_a and value_b are not identical.\n";
    }

    $self->status('success');

    return $self->result;
}

__PACKAGE__->meta->make_immutable;
1;
