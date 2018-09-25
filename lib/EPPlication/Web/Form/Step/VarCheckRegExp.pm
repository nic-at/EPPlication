package EPPlication::Web::Form::Step::VarCheckRegExp;
use HTML::FormHandler::Moose;
use EPPlication::Web::Role::Form::Step::Value;
extends 'EPPlication::Web::Form::Step::Base';
with
    'EPPlication::Web::Role::Form::Step::RegExp',
    Value();
1;
