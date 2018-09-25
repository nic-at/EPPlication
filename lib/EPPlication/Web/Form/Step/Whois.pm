package EPPlication::Web::Form::Step::Whois;
use HTML::FormHandler::Moose;
use EPPlication::Web::Role::Form::Step::Variable;
use EPPlication::Web::Role::Form::Step::Value;
extends 'EPPlication::Web::Form::Step::Base';

with
    Value(    name => 'domain',     default => '[% whois_domain %]' ),
    Variable( name => 'var_result', default => 'whois_response' ),
    Value(    name => 'port',       default => '[% whois_port %]' ),
    Value(    name => 'host',       default => '[% whois_host %]' ),
    ;

1;
