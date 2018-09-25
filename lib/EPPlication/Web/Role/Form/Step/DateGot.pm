package EPPlication::Web::Role::Form::Step::DateGot;
use HTML::FormHandler::Moose::Role;
use namespace::autoclean;

has_field 'date_got' => (
    label    => 'DateGot',
    type     => 'Text',
    required => 1,
    noupdate => 1,
);

around '_build_parameter_fields' => sub {
    my ($orig, $self) = @_;
    return [ @{ $self->$orig }, 'date_got' ];
};

1;
