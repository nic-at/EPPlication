package EPPlication::Web::Role::Form::Step::Date;
use HTML::FormHandler::Moose::Role;
use namespace::autoclean;

has_field 'date' => (
    type     => 'Text',
    label    => 'Date',
    required => 1,
    noupdate => 1,
);

around '_build_parameter_fields' => sub {
    my ($orig, $self) = @_;
    return [ @{ $self->$orig }, 'date' ];
};

1;
