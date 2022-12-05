package EPPlication::Step::HTTP;

use Moose;
use Try::Tiny;
use EPPlication::Role::Step::Parameters;
use namespace::autoclean;

with
  'EPPlication::Role::Step::Base',
  Parameters(parameter_list => [qw/ check_success var_status var_result method path headers body host port /]),
  'EPPlication::Role::Step::Client::HTTP',
  'EPPlication::Role::Step::Util::Encode',
  'EPPlication::Role::Step::Util::DecodeContent',
  ;

sub http_request {
    my ($self) = @_;

    my $var_result    = $self->var_result;
    my $check_success = $self->check_success;

    for my $config (qw/ host port /) {
        my $value_raw = $self->$config;
        my $value     = $self->process_template($value_raw);
        $self->http_client->$config($value);
    }

    $self->add_detail('URL: ' . $self->http_client->config_str);
    my $method  = $self->process_tt_value( 'Method', $self->method, { between => ": " } );
    my $path    = $self->process_tt_value( 'Path', $self->path, { between => ": " } );
    my $headers = $self->process_tt_value( 'Headers', $self->headers, { between => ":" } );
    $self->add_detail("check_success => $check_success");
    my $body = $self->process_tt_value( 'Body', $self->body, { between => ":\n", after => "\n" } );

    if ($headers) {
        try {
            $headers = $self->json2pl($headers);
        }
        catch {
            my $e = shift;
            die "Could not parse headers. ($e)";
        };
    }

    my $response = $self->http_client->request( $method, $path, $headers, $body );

    if ($check_success && !$response->is_success) {
        die $response->as_string . "\n";
    }

    return $response;
}

sub process {
    my ($self) = @_;

    my $var_result = $self->var_result;
    my $var_status = $self->var_status;

    try {
        my $response = $self->http_request();

        $self->add_detail( "Status: " . $response->code );
        $self->stash_set( $var_status => $response->code );

        $self->decode_content($response, $var_result);

        return $self->result;
    }
    catch {
        my $e = shift;
        $self->stash_set( $var_result => q{} );
        $self->stash_set( $var_status => q{} );
        die $e;
    };
}

__PACKAGE__->meta->make_immutable;
1;
