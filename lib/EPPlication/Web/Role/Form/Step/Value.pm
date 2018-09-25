package EPPlication::Web::Role::Form::Step::Value;

use strict;
use warnings;

use Package::Variant
    importing => ['HTML::FormHandler::Moose::Role'],
    subs      => [ qw/ has_field requires has around before after with / ];

sub make_variant {
    my ( $class, $target_package, %arguments ) = @_;

    my $name    = exists $arguments{name}  ? $arguments{name}  : 'value';
    my $label   = exists $arguments{label} ? $arguments{label} : ucfirst($name);
    my $default = exists $arguments{default} ? $arguments{default} : '';
    my $css_classes = exists $arguments{json_edit} && $arguments{json_edit}
                      ? 'detect-whitespace json-edit'
                      : 'detect-whitespace';

    has_field $name => (
        type         => 'Text',
        label        => $label,
        default      => $default,
        required     => 0,
        noupdate     => 1,
        not_nullable => 1,
        trim         => 0,
        element_attr => { class => $css_classes },
    );

    around '_build_parameter_fields' => sub {
        my ( $orig, $self ) = @_;
        return [ @{ $self->$orig }, $name ];
    };

    # equivalent to namespace::autoclean
    # in a non Package::Variant Moose file
    HTML::FormHandler::Moose::Role->unimport::out_of($target_package);
}

1;
