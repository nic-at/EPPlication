package EPPlication::Web::Form::Step::Diff;
use HTML::FormHandler::Moose;
use EPPlication::Web::Role::Form::Step::Variable;
use EPPlication::Web::Role::Form::Step::Value;
extends 'EPPlication::Web::Form::Step::Base';
with
    Value( name => 'value1' ),
    Value( name => 'value2' ),
    Variable();

1;
