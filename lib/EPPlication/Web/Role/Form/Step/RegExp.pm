package EPPlication::Web::Role::Form::Step::RegExp;
use HTML::FormHandler::Moose::Role;
use Try::Tiny;
use namespace::autoclean;

has_field 'regexp' => (
    type         => 'Text',
    label        => 'RegExp',
    required     => 1,
    noupdate     => 1,
    element_attr => { class => 'detect-whitespace' },
);
sub validate_regexp {
    my ( $self, $field ) = @_;
    my $regexp = $field->value;
    try {
        qr/$regexp/
    }
    catch {
        my $e = shift;
        $field->push_errors("Invalid RegExp ($e)\n");
    };
}

has_field 'modifiers' => (
    type         => 'Text',
    label        => 'modifiers',
    required     => 0,
    noupdate     => 1,
    not_nullable => 1,
    element_attr => { class => 'detect-whitespace' },
);
sub validate_modifiers {
    my ( $self, $field ) = @_;
    my $modifiers = $field->value;

    if ($modifiers !~ m/^[msixdualn]*$/) {
        $field->push_errors(qq/Invalid modifiers: "$modifiers"\n/);
    }
}

around '_build_parameter_fields' => sub {
    my ($orig, $self) = @_;
    return [ @{ $self->$orig }, 'regexp', 'modifiers' ];
};

1;
