package EPPlication::Web::Role::Form::Step::Boolean;

use Package::Variant
    importing => ['HTML::FormHandler::Moose::Role'],
    subs      => [ qw/ has_field requires has around before after with / ];

sub make_variant {
    my ( $class, $target_package, %arguments ) = @_;

    my $name    = $arguments{name};
    my $label   = exists $arguments{label} ? $arguments{label} : ucfirst($name);
    my $default = exists $arguments{default} ? $arguments{default} : '1';

    has_field $name => (
        type            => 'Boolean',
        label           => $label,
        default         => $default,
        noupdate        => 1,
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
