package EPPlication::Web::Form::Step::SeleniumContent;
use HTML::FormHandler::Moose;
use EPPlication::Web::Role::Form::Step::Variable;
extends 'EPPlication::Web::Form::Step::Base';
with
    Variable(name => 'identifier', default => 'selenium'),
    Variable(name => 'variable', default => 'selenium_content');

has_field 'content_type' => (
    type         => 'Select',
    empty_select => 'Select ...',
    required     => 1,
    noupdate     => 1,
    options      => [ map { { value => $_, label => $_ } } qw{ title body_text body_html } ],
);

around '_build_parameter_fields' => sub {
    my ($orig, $self) = @_;
    return [ @{ $self->$orig }, 'content_type' ];
};

1;
