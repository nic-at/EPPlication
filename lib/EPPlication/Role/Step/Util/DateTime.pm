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

    my $re = qr/(-?)(\d+)\ (years?|months?|days?|hours?|minutes?|seconds?)/xms;
    my @matches = $value =~ m/$re/g;
    die qq{Invalid duration format: "$value"} unless scalar @matches;

    my %unit_pattern_mapping = (
        year    => '%Y',
        years   => '%Y',
        month   => '%m',
        months  => '%m',
        day     => '%d',
        days    => '%d',
        hour    => '%H',
        hours   => '%H',
        minute  => '%M',
        minutes => '%M',
        second  => '%S',
        seconds => '%S',
    );

    my @patterns = ();
    while (scalar @matches) {
        my $negative = shift @matches;
        my $amount   = shift @matches;
        my $unit     = shift @matches;
        push @patterns, $unit_pattern_mapping{$unit} . ' ' . $unit;
    }
    my $pattern = join(', ', @patterns);
    my $formatter = DateTime::Format::Duration->new( pattern => $pattern, normalize => 1 );
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

sub format_duration {
    my ( $self, $duration ) = @_;
    my $duration_format_str = $duration->is_negative
        ? '-%Y years, -%m months, -%e days, -%H hours, -%M minutes, -%S seconds'
        : '%Y years, %m months, %e days, %H hours, %M minutes, %S seconds';
    my $formatter = DateTime::Format::Duration->new(
        pattern => $duration_format_str,
        normalize => 1,
    );
    return $formatter->format_duration($duration);
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
