package EPPlication::Web::Form::Step::VarVal;
use HTML::FormHandler::Moose;
use EPPlication::Web::Role::Form::Step::Value;
use EPPlication::Web::Role::Form::Step::Variable;
extends 'EPPlication::Web::Form::Step::Base';
with
    'EPPlication::Web::Role::Form::Step::Global',
    Value( json_edit => 1 ),
    Variable();
1;
