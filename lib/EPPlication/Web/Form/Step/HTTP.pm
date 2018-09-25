package EPPlication::Web::Form::Step::HTTP;
use HTML::FormHandler::Moose;
use EPPlication::Web::Role::Form::Step::Variable;
use EPPlication::Web::Role::Form::Step::Value;
use EPPlication::Web::Role::Form::Step::Boolean;
use EPPlication::Web::Role::Form::Step::TextArea;
use namespace::autoclean;
extends 'EPPlication::Web::Form::Step::Base';

with
    'EPPlication::Web::Role::Form::Step::ValidateXML',
    'EPPlication::Web::Role::Form::Step::ValidateJSON',
    TextArea( name => 'body',          json_edit => 1, rows => 1 ),
    Value(    name => 'method',        default => '[% http_method %]' ),
    'EPPlication::Web::Role::Form::Step::Path',
    Value(    name => 'port',          default => '[% http_port %]' ),
    Value(    name => 'host',          default => '[% http_host %]' ),
    Value(    name => 'headers',       default => '[% http_headers %]', json_edit => 1 ),
    Variable( name => 'var_status',    default => 'http_status' ),
    Variable( name => 'var_result',    default => 'http_response' ),
    Boolean(  name => 'check_success', default => 1 ),
    ;

1;
