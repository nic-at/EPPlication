package EPPlication::Web::Role::Form::Step::TextArea;

use strict;
use warnings;

use Package::Variant
    importing => ['HTML::FormHandler::Moose::Role'],
    subs      => [ qw/ has_field requires has around before after with / ];

sub make_variant {
    my ( $class, $target_package, %arguments ) = @_;

    my $name    = exists $arguments{name}  ? $arguments{name}  : 'value';
    my $label   = exists $arguments{label} ? $arguments{label} : ucfirst($name);
    my $required = exists $arguments{required} ? $arguments{required} : 1;

    my %element_attr;

    if ( exists $arguments{rows} ) {
        $element_attr{rows} = $arguments{rows};
    }
    if ( exists $arguments{json_edit} ) {
        $element_attr{class} = 'json-edit';
    }

    has_field $name => (
        type         => 'TextArea',
        label        => $label,
        required     => $required,
        noupdate     => 1,
        not_nullable => 1,
        trim         => 0,
        ( scalar keys %element_attr )
            ? (element_attr => \%element_attr)
            : (),
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
