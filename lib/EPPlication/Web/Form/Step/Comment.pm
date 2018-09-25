package EPPlication::Web::Form::Step::Comment;
use HTML::FormHandler::Moose;
use EPPlication::Web::Role::Form::Step::TextArea;
extends 'EPPlication::Web::Form::Step::Base';
with TextArea( name => 'comment', rows => 10 );

1;
