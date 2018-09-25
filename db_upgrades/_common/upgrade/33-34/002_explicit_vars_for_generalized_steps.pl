#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use JSON;

# EPPConnect
# new param 'var_result'

# EPPFrame
# new param 'var_result'

# SOAPFrame
# new param 'var_result'

# RESTRequest
# new param 'var_result'

# RESTStatus
# new param 'var_result'
# param 'var_status' instead of 'variable'

# VarQueryPath
# param 'var_source' instead of 'source'
# param 'var_result' instead of 'variable'

# CountQueryPath
# param 'var_source' instead of 'source'
# param 'var_result' instead of 'variable'

use
  DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator::ScriptHelpers
  'schema_from_schema_loader';

schema_from_schema_loader(
    { naming => { ALL => 'v8', force_ascii => 1 } },
    sub {
        my ( $schema, $versions ) = @_;

        my $step_rs = $schema->resultset('Step');
        while ( my $step = $step_rs->next ) {
            if ($step->type eq 'EPPConnect' || $step->type eq 'EPPFrame') {
                add_param($step, 'var_result', 'epp_response');
            }
            elsif ($step->type eq 'SOAPFrame') {
                add_param($step, 'var_result', 'soap_response');
            }
            elsif ($step->type eq 'RESTRequest') {
                add_param($step, 'var_result', 'rest_response');
            }
            elsif ($step->type eq 'RESTStatus') {
                replace_param($step, 'variable', 'var_status');
                add_param($step, 'var_result', 'rest_response');
            }
            elsif ($step->type eq 'VarQueryPath' || $step->type eq 'CountQueryPath') {
                replace_param($step, 'variable', 'var_result');

                say $step->type . '(' . $step->id . ') replace param "source" with "var_source"';
                my $params_raw = $step->get_column('parameters');
                my $params = from_json($params_raw);
                my $source = delete $params->{source};
                if ( $source eq '_epp_response' ) {
                    $params->{input} = '[% epp_response %]';
                }
                elsif ( $source eq '_soap_response' ) {
                    $params->{input} = '[% soap_response %]';
                }
                elsif ( $source eq '_rest_response' ) {
                    $params->{input} = '[% rest_response %]';
                }
                else {
                    die "Unknown source value: " . $source;
                }
                $step->set_column('parameters' => to_json($params));
                $step->update();
            }
        }
    }
);

sub add_param {
    my ($step, $key, $value) = @_;

    say $step->type . '(' . $step->id . ") add param $key => $value";
    my $params_raw = $step->get_column('parameters');
    my $params = from_json($params_raw);
    $params->{$key} = $value;
    $step->set_column( 'parameters' => to_json($params) );
    $step->update();
}
sub replace_param {
    my ($step, $old, $new) = @_;

    say $step->type . '(' . $step->id . ") replace param $old => $new";
    my $params_raw = $step->get_column('parameters');
    my $params = from_json($params_raw);
    $params->{$new} = delete $params->{$old};
    $step->set_column( 'parameters' => to_json($params) );
    $step->update();
}
