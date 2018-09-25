package EPPlication::Web::Role::Form::Step::DateFormatStr;
use HTML::FormHandler::Moose::Role;
use Try::Tiny;
use DateTime::Format::Strptime;
use namespace::autoclean;

has_field 'date_format_str' => (
    label    => 'DateFormatStr',
    type     => 'Text',
    required => 1,
    noupdate => 1,
);

around '_build_parameter_fields' => sub {
    my ($orig, $self) = @_;
    return [ @{ $self->$orig }, 'date_format_str' ];
};

sub validate_date_format_str {
    my ( $self, $field ) = @_;
    my $pattern = $field->value;
    try {
        my $strp = DateTime::Format::Strptime->new(
            pattern  => $pattern,
            on_error => 'croak',
        );
    }
    catch {
        my $e = shift;
        $field->push_errors("Invalid datetime format for pattern: $pattern. ($e)");
    };
}

1;
