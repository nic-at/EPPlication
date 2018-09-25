package EPPlication::Web::Form::Step::DateAdd;
use HTML::FormHandler::Moose;
use EPPlication::Web::Role::Form::Step::Variable;
extends 'EPPlication::Web::Form::Step::Base';
with
    'EPPlication::Web::Role::Form::Step::Date',
    'EPPlication::Web::Role::Form::Step::Duration',
    Variable();
1;
