package EPPlication::Step::REST;

use Moose;
use Try::Tiny;
use EPPlication::Role::Step::Parameters;

with
  'EPPlication::Role::Step::Base',
  Parameters(parameter_list => [qw/ check_success var_status var_result method path headers body host port /]),
  'EPPlication::Role::Step::Client::REST',
  'EPPlication::Role::Step::Util::Encode',
  'EPPlication::Role::Step::Util::DecodeContent',
  ;

sub rest_request {
    my ($self) = @_;

    my $path_raw      = $self->path;
    my $path          = $self->process_template($path_raw);
    my $headers_raw   = $self->headers;
    my $headers       = $self->process_template($headers_raw);
    my $method        = $self->method;
    my $var_result    = $self->var_result;
    my $check_success = $self->check_success;

    for my $config (qw/ host port /) {
        my $value_raw = $self->$config;
        my $value     = $self->process_template($value_raw);
        $self->rest_client->$config($value);
    }

    $self->add_detail("$var_result => $method " . $self->rest_client->config_str . $path . "\n");
    $self->add_detail("headers => $headers");
    $self->add_detail("check_success => $check_success");

    my $body = $self->process_tt_value( 'JSON', $self->body, { between => ":\n", after => "\n" } );

    if ($headers) {
        try {
            $headers = $self->json2pl($headers);
        }
        catch {
            my $e = shift;
            die "could not parse headers. ($e)";
        };
    }

    my $response = $self->rest_client->request( $method, $path, $headers, $body );

    return $response;
}

sub process {
    my ($self) = @_;

    my $var_result    = $self->var_result;
    my $var_status    = $self->var_status;
    my $check_success = $self->check_success;

    try {
        my $response = $self->rest_request();

        $self->decode_content($response, $var_result);

        if (!$response->is_success) {
            $self->add_detail( "Status: " . $response->status_line );
            if ($check_success) {
                die "Request failed.\n";
            }
        }

        $self->stash_set( $var_status => $response->code );

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
