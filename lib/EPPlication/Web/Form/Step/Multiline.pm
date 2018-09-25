package EPPlication::Web::Form::Step::Multiline;
use HTML::FormHandler::Moose;
use EPPlication::Web::Role::Form::Step::Variable;
use EPPlication::Web::Role::Form::Step::TextArea;
extends 'EPPlication::Web::Form::Step::Base';
with
    'EPPlication::Web::Role::Form::Step::Global',
    TextArea( label => 'Text', json_edit => 1, rows => 10 ),
    Variable();
1;
