package EPPlication::Web::Form::Step::DateCheck;
use HTML::FormHandler::Moose;
extends 'EPPlication::Web::Form::Step::Base';
with qw/
    EPPlication::Web::Role::Form::Step::DateGot
    EPPlication::Web::Role::Form::Step::DateExpected
    EPPlication::Web::Role::Form::Step::Duration
    /;
1;
