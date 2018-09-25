package EPPlication::Web::Form::Step::REST;
use HTML::FormHandler::Moose;
use EPPlication::Web::Role::Form::Step::Variable;
use EPPlication::Web::Role::Form::Step::Value;
use EPPlication::Web::Role::Form::Step::Boolean;
extends 'EPPlication::Web::Form::Step::Base';

with
    'EPPlication::Web::Role::Form::Step::ValidateJSON',
    Value(    name => 'body',          json_edit => 1 ),
    'EPPlication::Web::Role::Form::Step::Method',
    'EPPlication::Web::Role::Form::Step::Path',
    Value(    name => 'port',          default => '[% rest_port %]' ),
    Value(    name => 'host',          default => '[% rest_host %]' ),
    Value(    name => 'headers',       default => '[% rest_headers_default %]' ),
    Variable( name => 'var_status',    default => 'rest_status' ),
    Variable( name => 'var_result',    default => 'rest_response' ),
    Boolean(  name => 'check_success', default => 1 ),
    ;

1;
