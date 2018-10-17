package EPPlication::Web::Form::Step::SeleniumClick;
use HTML::FormHandler::Moose;
use EPPlication::Web::Role::Form::Step::Variable;
use EPPlication::Web::Role::Form::Step::Value;
extends 'EPPlication::Web::Form::Step::Base';
with
    Value(name => 'selector'),
    'EPPlication::Web::Role::Form::Step::Locator',
    Variable(name => 'identifier', default => 'selenium');
1;
