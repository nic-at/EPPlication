package EPPlication::Web::Role::Form::Step::Duration;
use HTML::FormHandler::Moose::Role;
use namespace::autoclean;

has_field 'duration' => (
    type     => 'Text',
    required => 1,
    noupdate => 1,
);

around '_build_parameter_fields' => sub {
    my ( $orig, $self ) = @_;
    return [ @{ $self->$orig }, 'duration' ];
};

1;
