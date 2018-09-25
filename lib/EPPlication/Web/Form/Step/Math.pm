package EPPlication::Web::Form::Step::Math;
use HTML::FormHandler::Moose;
use EPPlication::Web::Role::Form::Step::Value;
use EPPlication::Web::Role::Form::Step::Variable;
extends 'EPPlication::Web::Form::Step::Base';
with
    Value( name => 'value_a' ),
    Value( name => 'value_b' ),
    'EPPlication::Web::Role::Form::Step::Operator',
    Variable();
1;
