package EPPlication::Web::Role::Form::Step::Rand;
use HTML::FormHandler::Moose::Role;
use EPPlication::String::Random qw/ rand_regex /;
use Try::Tiny;
use namespace::autoclean;

has_field 'rand' => (
    type     => 'Text',
    required => 1,
    noupdate => 1,
    element_attr => { class => 'detect-whitespace' },
);
sub validate_rand {
    my ( $self, $field ) = @_;
    my $rand = $field->value;
    try {
        rand_regex($rand);
    }
    catch {
        my $e = shift;
        $field->push_errors("Invalid rand ($e)");
    };
}

around '_build_parameter_fields' => sub {
    my ($orig, $self) = @_;
    return [ @{ $self->$orig }, 'rand' ];
};

1;
