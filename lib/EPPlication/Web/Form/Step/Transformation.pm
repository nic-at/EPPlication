package EPPlication::Web::Form::Step::Transformation;
use HTML::FormHandler::Moose;
use EPPlication::Web::Role::Form::Step::Variable;
use EPPlication::Web::Role::Form::Step::Value;
extends 'EPPlication::Web::Form::Step::Base';
with
    Variable( name => 'var_result' ),
    Value( name => 'input' ),
    ;

use Module::Pluggable
    search_path => 'EPPlication::Step::Transformation',
    except      => 'EPPlication::Step::Transformation::Factory';

has_field 'transformation' => (
    type         => 'Select',
    empty_select => 'Select ...',
    required     => 1,
    noupdate     => 1,
);
sub options_transformation {
    my ($self) = @_;
    my @options = map {
        {
            label => (split('::',$_))[-1],
            value => (split('::',$_))[-1],
        }
    } $self->plugins;
    return \@options;
}

around '_build_parameter_fields' => sub {
    my ($orig, $self) = @_;
    return [ @{ $self->$orig }, 'transformation' ];
};

1;
