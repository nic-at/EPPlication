package EPPlication::Web::Role::Form::Step::Path;
use HTML::FormHandler::Moose::Role;
use namespace::autoclean;

has_field 'path' => (
    type         => 'Text',
    required     => 1,
    noupdate     => 1,
    element_attr => { class => 'detect-whitespace' },
);

around '_build_parameter_fields' => sub {
    my ($orig, $self) = @_;
    return [ @{ $self->$orig }, 'path' ];
};

1;
