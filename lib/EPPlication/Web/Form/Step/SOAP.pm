package EPPlication::Web::Form::Step::SOAP;
use HTML::FormHandler::Moose;
use EPPlication::Web::Role::Form::Step::Variable;
use EPPlication::Web::Role::Form::Step::Value;
use EPPlication::Web::Role::Form::Step::TextArea;
extends 'EPPlication::Web::Form::Step::Base';

with
    TextArea( name => 'body', label => 'XML', rows => 10 ),
    'EPPlication::Web::Role::Form::Step::ValidateXML',
    'EPPlication::Web::Role::Form::Step::Method',
    Variable( name => 'var_result', default => 'soap_response' ),
    Value(    name => 'path',       default => '[% soap_path %]' ),
    Value(    name => 'port',       default => '[% soap_port %]' ),
    Value(    name => 'host',       default => '[% soap_host %]' ),
    Value(    name => 'headers',    default => '[% soap_headers_default %]' ),
    ;

1;
