package EPPlication::Web::Form::Step::ForLoop;
use HTML::FormHandler::Moose;
use EPPlication::Web::Role::Form::Step::Value;
use EPPlication::Web::Role::Form::Step::Variable;
extends 'EPPlication::Web::Form::Step::Base';
with
    Value( name => 'values', json_edit => 1 ),
    Variable(),
    'EPPlication::Web::Role::Form::Step::SubTest',
    ;

1;
