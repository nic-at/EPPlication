package EPPlication::Web::Role::Form::Step::Variable;

use Package::Variant
    importing => ['HTML::FormHandler::Moose::Role'],
    subs      => [ qw/ has_field requires has around before after with / ];

sub make_variant {
    my ( $class, $target_package, %arguments ) = @_;

    my $name  = exists $arguments{name}  ? $arguments{name}  : 'variable';
    my $label = exists $arguments{label} ? $arguments{label} : ucfirst($name);
    my $default = exists $arguments{default} ? $arguments{default} : '';

    has_field $name => (
        type            => 'Text',
        label           => $label,
        default         => $default,
        required        => 1,
        noupdate        => 1,
        trim            => 0,
        element_attr    => { class => 'detect-whitespace' },
        validate_method => sub {
            my ( $self, $field ) = @_;
            $field->push_errors( '"'
                  . $field->value
                  . '" is not a valid variable name. only use a-z, A-Z, 0-9, _'
            ) unless $field->value =~ /^[a-zA-Z0-9_]+$/xms;
            $field->push_errors( '"'
                  . $field->value
                  . '" must not begin with double underscore. '
            ) if $field->value =~ /^__/xms;
        }
    );

    around '_build_parameter_fields' => sub {
        my ($orig, $self) = @_;
        return [ @{ $self->$orig }, $name ];
    };

    # equivalent to namespace::autoclean
    # in a non Package::Variant Moose file
    HTML::FormHandler::Moose::Role->unimport::out_of($target_package);
}

1;
