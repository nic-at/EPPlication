package EPPlication::Web::Role::Form::Step::Global;
use HTML::FormHandler::Moose::Role;
use namespace::autoclean;

has_field 'global' => (
    type     => 'Boolean',
    noupdate => 1,
);

around '_build_parameter_fields' => sub {
    my ($orig, $self) = @_;
    return [ @{ $self->$orig }, 'global' ];
};

1;
