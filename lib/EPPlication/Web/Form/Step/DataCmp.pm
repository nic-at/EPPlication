package EPPlication::Web::Form::Step::DataCmp;
use HTML::FormHandler::Moose;
use EPPlication::Web::Role::Form::Step::Value;
extends 'EPPlication::Web::Form::Step::Base';
with
    Value( name => 'value_a', json_edit => 1 ),
    Value( name => 'value_b', json_edit => 1 ),
    ;

1;
