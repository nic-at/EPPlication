package EPPlication::Role::Step::Util::DateTime;
use Moose::Role;
use DateTime;
use DateTime::Format::ISO8601;
use DateTime::Format::Strptime;
use DateTime::Format::Duration;

sub parse_datetime {
    my ( $self, $value ) = @_;

    return DateTime->now(time_zone => 'UTC')
      if $value eq 'now()';

    my $formatter = DateTime::Format::ISO8601->new;
    return $formatter->parse_datetime($value);
}

sub parse_duration {
    my ( $self, $value ) = @_;

    my $re = qr/^(-?)(\d+)\ (years?|months?|days?|hours?|minutes?|seconds?)$/xms;
    die qq{Invalid duration format: "$value"}
        unless $value =~ m/$re/;

    my %unit_pattern_mapping = (
        year    => '%Y',
        years   => '%Y',
        month   => '%m',
        months  => '%m',
        day     => '%e',
        days    => '%e',
        hour    => '%H',
        hours   => '%H',
        minute  => '%M',
        minutes => '%M',
        second  => '%S',
        seconds => '%S',
    );
    my $negative = $1;
    my $amount   = $2;
    my $unit     = $3;
    my $pattern  = $unit_pattern_mapping{$unit};
    my $formatter = DateTime::Format::Duration->new( pattern => $pattern );
    my $dur = $formatter->parse_duration($value);

    die "$value is a zero duration.\n"
      if $dur->is_zero;

    return $dur;
}

sub format_datetime {
    my ( $self, $date, $date_format_str ) = @_;

    my $formatter = DateTime::Format::Strptime->new(
        pattern  => $date_format_str,
        on_error => 'croak',
    );
    my $formatted_date = $formatter->format_datetime($date);
    return $formatted_date;
}

sub date_to_str {
    my ( $self, $date ) = @_;
    my $formatter = DateTime::Format::Strptime->new(
        pattern  => '%Y-%m-%dT%H:%M:%S.%6NZ', # ISO8601
        on_error => 'croak',
    );
    my $formatted_date = $formatter->format_datetime($date);
    return $formatted_date;
}

1;
