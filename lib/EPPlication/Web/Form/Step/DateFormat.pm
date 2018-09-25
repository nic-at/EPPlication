package EPPlication::Web::Form::Step::DateFormat;
use HTML::FormHandler::Moose;
use EPPlication::Web::Role::Form::Step::Variable;
extends 'EPPlication::Web::Form::Step::Base';
with
    'EPPlication::Web::Role::Form::Step::DateFormatStr',
    'EPPlication::Web::Role::Form::Step::Date',
    Variable();

1;
