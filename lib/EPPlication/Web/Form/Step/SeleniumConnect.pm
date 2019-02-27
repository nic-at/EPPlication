package EPPlication::Web::Form::Step::SeleniumConnect;
use HTML::FormHandler::Moose;
use EPPlication::Web::Role::Form::Step::Variable;
extends 'EPPlication::Web::Form::Step::Base';
with
    Variable(name => 'port', default => '4444'),
    Variable(name => 'host', default => 'epplication_selenium'),
    Variable(name => 'identifier', default => 'selenium');
1;
