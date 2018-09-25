package EPPlication::Web::Form::Step::CountQueryPath;
use HTML::FormHandler::Moose;
use EPPlication::Web::Role::Form::Step::Variable;
use EPPlication::Web::Role::Form::Step::Value;
extends 'EPPlication::Web::Form::Step::Base';
with
    'EPPlication::Web::Role::Form::Step::QueryPath',
    Variable( name => 'var_result' ),
    Value( name => 'input' ),
    ;
1;
