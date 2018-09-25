package EPPlication::Step::DateCheck;

use Moose;
use EPPlication::Role::Step::Parameters;

with
  'EPPlication::Role::Step::Base',
  Parameters(parameter_list => [qw/ duration date_got date_expected /]),
  'EPPlication::Role::Step::Util::DateTime',
  ;

sub process {
    my ($self) = @_;

    my $date_got_str      = $self->process_tt_value( 'date_got', $self->date_got );
    my $date_expected_str = $self->process_tt_value( 'date_expected', $self->date_expected );
    my $duration_str      = $self->process_tt_value( 'duration', $self->duration );

    $self->add_detail("$date_expected_str +/- $duration_str");

    my $date_got      = $self->parse_datetime($date_got_str);
    my $date_expected = $self->parse_datetime($date_expected_str);
    my $duration      = $self->parse_duration($duration_str);

    my $date_lower_boundary =
      $date_expected->clone->subtract_duration($duration);
    my $date_upper_boundary = $date_expected->clone->add_duration($duration);
    if ( $date_got < $date_lower_boundary ) {
        die "date_got exceeds lower boundary.\n"
          . "Expected: "
          . $self->date_to_str($date_expected) . "\n"
          . "Got:      "
          . $self->date_to_str($date_got) . "\n"
          . "Lower:    "
          . $self->date_to_str($date_lower_boundary) . "\n"
          . "Upper:    "
          . $self->date_to_str($date_upper_boundary) . "\n"
          . "Duration: $duration_str\n";
    }
    if ( $date_got > $date_upper_boundary ) {
        die "date_got exceeds upper boundary.\n"
          . "Expected: "
          . $self->date_to_str($date_expected) . "\n"
          . "Got:      "
          . $self->date_to_str($date_got) . "\n"
          . "Lower:    "
          . $self->date_to_str($date_lower_boundary) . "\n"
          . "Upper:    "
          . $self->date_to_str($date_upper_boundary) . "\n"
          . "Duration: $duration_str\n";
    }

    $self->status('success');

    return $self->result;
}

__PACKAGE__->meta->make_immutable;
1;
