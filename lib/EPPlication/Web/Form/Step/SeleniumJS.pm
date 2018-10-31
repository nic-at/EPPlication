package EPPlication::Web::Form::Step::SeleniumJS;
use HTML::FormHandler::Moose;
use EPPlication::Web::Role::Form::Step::Value;
use EPPlication::Web::Role::Form::Step::Variable;
extends 'EPPlication::Web::Form::Step::Base';
with
    Value(name => 'javascript'),
    Variable(name => 'identifier', default => 'selenium');
1;
