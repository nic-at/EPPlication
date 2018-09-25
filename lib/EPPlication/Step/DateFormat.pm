package EPPlication::Step::DateFormat;

use Moose;
use EPPlication::Role::Step::Parameters;

with
  'EPPlication::Role::Step::Base',
  Parameters( parameter_list => [qw/ variable date date_format_str /] ),
  'EPPlication::Role::Step::Util::DateTime',
  ;

sub process {
    my ($self) = @_;

    my $variable = $self->variable;
    $self->add_detail("Variable: $variable");

    my $date_format_str = $self->date_format_str;
    $self->add_detail("Format: $date_format_str");

    my $date_str = $self->process_tt_value( 'Date', $self->date );
    my $date     = $self->parse_datetime($date_str);

    my $formatted_date = $self->format_datetime( $date, $date_format_str );
    $self->add_detail($formatted_date);
    $self->stash_set( $variable => $formatted_date );

    return $self->result;
}

__PACKAGE__->meta->make_immutable;
1;
