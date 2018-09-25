package EPPlication::Web::Role::Form::Step::QueryPath;
use HTML::FormHandler::Moose::Role;
use namespace::autoclean;

has_field 'query_path' => (
    type     => 'Text',
    label    => 'Query Path',
    required => 1,
    noupdate => 1,
    element_attr => { class => 'detect-whitespace' },
);

around '_build_parameter_fields' => sub {
    my ($orig, $self) = @_;
    return [ @{ $self->$orig }, 'query_path' ];
};

1;
