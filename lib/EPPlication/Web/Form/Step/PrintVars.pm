package EPPlication::Web::Form::Step::PrintVars;
use HTML::FormHandler::Moose;
use EPPlication::Web::Role::Form::Step::Value;
extends 'EPPlication::Web::Form::Step::Base';
with Value( name => 'filter' );
1;
