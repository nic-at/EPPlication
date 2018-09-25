package EPPlication::Web::Form::Step::Script;
use HTML::FormHandler::Moose;
use EPPlication::Web::Role::Form::Step::Value;
use EPPlication::Web::Role::Form::Step::Variable;
extends 'EPPlication::Web::Form::Step::Base';
with
  Value( name => 'command' ),
  Variable( name => 'var_stdout', label => 'STDOUT (Variable)', default => 'script_response' );
1;
