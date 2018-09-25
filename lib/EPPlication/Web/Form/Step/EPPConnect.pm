package EPPlication::Web::Form::Step::EPPConnect;
use HTML::FormHandler::Moose;
use EPPlication::Web::Role::Form::Step::Variable;
use EPPlication::Web::Role::Form::Step::Value;
use EPPlication::Web::Role::Form::Step::Boolean;
use EPPlication::Web::Role::Form::Step::TextArea;
extends 'EPPlication::Web::Form::Step::Base';
with
  TextArea( name => 'ssl_key', label => 'SSL_key', rows => 5 ),
  TextArea( name => 'ssl_cert', label => 'SSL_cert', rows => 5 ),
  Boolean(  name => 'ssl_use_cert', label => 'SSL_use_cert', default => 0 ),
  Value(    name => 'ssl', label => 'SSL', default => '[% epp_ssl %]' ),
  Value(    name => 'port', default => '[% epp_port %]' ),
  Value(    name => 'host', default => '[% epp_host %]' ),
  Variable( name => 'var_result', default => 'epp_response' ),
  ;

has_field '+ssl_key' => (
    required      => 0,
    required_when => { ssl_use_cert => 1 },
);

has_field '+ssl_cert' => (
    required => 0,
    required_when => { ssl_use_cert => 1 },
);

my $js = <<'HERE';
<script>
(function () {
    'use strict';
    $(document).ready(function() {

        var box = $('input#ssl_use_cert');
        var show_hide_ssl_fields = function() {
            if (box[0].checked) {
                $('textarea#ssl_key').closest('.form-group').show()
                $('textarea#ssl_cert').closest('.form-group').show()
            }
            else {
                $('textarea#ssl_key').closest('.form-group').hide()
                $('textarea#ssl_cert').closest('.form-group').hide()
            }
        };
        show_hide_ssl_fields();
        box.change(show_hide_ssl_fields);
    });
})();
</script>
HERE

has_field '_js_show_hide_ssl_fields' => (
    type => 'Display',
    html => $js,
);

1;
