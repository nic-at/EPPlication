package EPPlication::Web::Form::Step::VarRand;
use HTML::FormHandler::Moose;
use EPPlication::Web::Role::Form::Step::Variable;
extends 'EPPlication::Web::Form::Step::Base';
with
    'EPPlication::Web::Role::Form::Step::Rand',
    Variable();

1;
