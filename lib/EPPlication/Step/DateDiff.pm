package EPPlication::Step::DateDiff;

use Moose;
use EPPlication::Role::Step::Parameters;

with
  'EPPlication::Role::Step::Base',
  Parameters(parameter_list => [qw/ variable date1 date2 /]),
  'EPPlication::Role::Step::Util::DateTime',
  ;

sub process {
    my ($self) = @_;

    my $variable     = $self->variable;
    my $date1_raw    = $self->date1;
    my $date2_raw    = $self->date2;

    my $date1_str    = $self->process_tt_value( 'Date', $self->date1 );
    my $date2_str    = $self->process_tt_value( 'Date', $self->date2 );

    my $date1     = $self->parse_datetime($date1_str);
    my $date2     = $self->parse_datetime($date2_str);
    #my $diff      = $date->add_duration($duration);

    #my $new_date_as_str = $self->date_to_str($new_date);
    #$self->add_detail($new_date_as_str);
    #$self->stash_set( $variable => $new_date_as_str );
use DateTime;
use DateTime::Format::ISO8601;

my $formatter = DateTime::Format::ISO8601->new;

my $diff = $date2->subtract_datetime($date1);
#my $deltas = $diff->deltas;

#use DateTime::Format::Duration;
#my $diff_formatter = DateTime::Format::Duration->new( pattern => $format_str );
    #pattern => '%Y years, %m months, %e days, %H hours, %M minutes, %S seconds'
    #my $deltas_str = $diff_formatter->format_duration($diff);

my $deltas_str = $self->format_duration($diff);

$self->add_detail($deltas_str);
$self->stash_set( $variable => $deltas_str );
    return $self->result;
}

__PACKAGE__->meta->make_immutable;
1;
