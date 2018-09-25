package EPPlication::Web::Form::Step::DBConnect;
use HTML::FormHandler::Moose;
use EPPlication::Web::Role::Form::Step::Value;
extends 'EPPlication::Web::Form::Step::Base';
with
  Value( name => 'password', default => '[% db_password %]' ),
  Value( name => 'username', default => '[% db_username %]' ),
  Value( name => 'database', default => '[% db_database %]' ),
  Value( name => 'port',     default => '[% db_port %]' ),
  Value( name => 'host',     default => '[% db_host %]' ),
  ;
1;
