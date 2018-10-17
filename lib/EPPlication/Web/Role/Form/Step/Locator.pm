package EPPlication::Web::Role::Form::Step::Locator;
use HTML::FormHandler::Moose::Role;
use namespace::autoclean;

has_field 'locator' => (
    type         => 'Select',
    empty_select => 'Select ...',
    required     => 1,
    noupdate     => 1,
    options      => [ map { { value => $_, label => $_ } } qw{ xpath css id name link link_text } ],
);

around '_build_parameter_fields' => sub {
    my ($orig, $self) = @_;
    return [ @{ $self->$orig }, 'locator' ];
};

1;
