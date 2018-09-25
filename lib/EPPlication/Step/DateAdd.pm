package EPPlication::Step::DateAdd;

use Moose;
use EPPlication::Role::Step::Parameters;

with
  'EPPlication::Role::Step::Base',
  Parameters(parameter_list => [qw/ variable duration date /]),
  'EPPlication::Role::Step::Util::DateTime',
  ;

sub process {
    my ($self) = @_;

    my $variable     = $self->variable;
    my $date_raw     = $self->date;
    my $duration_raw = $self->duration;

    my $date_str     = $self->process_tt_value( 'Date', $self->date );
    my $duration_str = $self->process_tt_value( 'Duration', $self->duration );

    my $date     = $self->parse_datetime($date_str);
    my $duration = $self->parse_duration($duration_str);
    my $new_date = $date->add_duration($duration);

    my $new_date_as_str = $self->date_to_str($new_date);
    $self->add_detail($new_date_as_str);
    $self->stash_set( $variable => $new_date_as_str );

    return $self->result;
}

__PACKAGE__->meta->make_immutable;
1;
