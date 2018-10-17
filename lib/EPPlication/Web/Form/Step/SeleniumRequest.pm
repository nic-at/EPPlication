package EPPlication::Web::Form::Step::SeleniumRequest;
use HTML::FormHandler::Moose;
use EPPlication::Web::Role::Form::Step::Variable;
use EPPlication::Web::Role::Form::Step::Value;
extends 'EPPlication::Web::Form::Step::Base';
with
    Value(name => 'url'),
    Variable(name => 'identifier', default => 'selenium');
1;
