package EPPlication::Web::Form::Step::SeleniumDisconnect;
use HTML::FormHandler::Moose;
use EPPlication::Web::Role::Form::Step::Variable;
extends 'EPPlication::Web::Form::Step::Base';
with
    Variable(name => 'identifier', default => 'selenium');
1;
