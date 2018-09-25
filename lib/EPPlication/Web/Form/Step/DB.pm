package EPPlication::Web::Form::Step::DB;
use HTML::FormHandler::Moose;
use EPPlication::Web::Role::Form::Step::Variable;
use EPPlication::Web::Role::Form::Step::Value;
extends 'EPPlication::Web::Form::Step::Base';

with
    Variable( name => 'var_result', default => 'db_response' ),
    Value( name => 'sql' ),
    ;

1;
