package EPPlication::Web::Form::Step::EPP;
use HTML::FormHandler::Moose;
use EPPlication::Web::Role::Form::Step::Variable;
use EPPlication::Web::Role::Form::Step::TextArea;
extends 'EPPlication::Web::Form::Step::Base';

with
    'EPPlication::Web::Role::Form::Step::ValidateXML',
    TextArea( name => 'body', label => 'XML', rows => 10 ),
    Variable( name => 'var_result', default => 'epp_response' ),
    ;

1;
