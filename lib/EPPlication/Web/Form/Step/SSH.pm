package EPPlication::Web::Form::Step::SSH;
use HTML::FormHandler::Moose;
use EPPlication::Web::Role::Form::Step::Value;
use EPPlication::Web::Role::Form::Step::Variable;
extends 'EPPlication::Web::Form::Step::Base';
with
  Value( name => 'command' ),
  Value( name => 'ssh_user', label => 'SSH User', default => '[% ssh_user %]' ),
  Value( name => 'ssh_port', label => 'SSH Port', default => '[% ssh_port %]' ),
  Value( name => 'ssh_host', label => 'SSH Host', default => '[% ssh_host %]' ),
  Variable( name => 'var_stdout', label => 'STDOUT (Variable)', default => 'ssh_response' );
1;
