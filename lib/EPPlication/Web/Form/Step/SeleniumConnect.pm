package EPPlication::Web::Form::Step::SeleniumConnect;
use HTML::FormHandler::Moose;
use EPPlication::Web::Role::Form::Step::Variable;
use EPPlication::Web::Role::Form::Step::Value;
extends 'EPPlication::Web::Form::Step::Base';
with
    Value(name => 'port', default => '4444'),
    Value(name => 'host', default => 'epplication-selenium'),
    Variable(name => 'identifier', default => 'selenium');
1;
