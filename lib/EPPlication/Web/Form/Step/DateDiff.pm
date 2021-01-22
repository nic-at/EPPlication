package EPPlication::Web::Form::Step::DateDiff;
use HTML::FormHandler::Moose;
use EPPlication::Web::Role::Form::Step::Variable;
extends 'EPPlication::Web::Form::Step::Base';
with Variable();

has_field 'date1' => (
    type     => 'Text',
    label    => 'Date 1',
    required => 1,
    noupdate => 1,
);
has_field 'date2' => (
    type     => 'Text',
    label    => 'Date 2',
    required => 1,
    noupdate => 1,
);

around '_build_parameter_fields' => sub {
    my ($orig, $self) = @_;
    return [ @{ $self->$orig }, 'date1', 'date2' ];
};

1;
