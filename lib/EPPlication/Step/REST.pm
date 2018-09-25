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
    my $body_raw      = $self->body;
    my $var_result    = $self->var_result;
    my $check_success = $self->check_success;

    for my $config (qw/ host port /) {
        my $value_raw = $self->$config;
        my $value     = $self->process_template($value_raw);
        $self->rest_client->$config($value);
    }

    $self->add_detail("check_success => $check_success");
    $self->add_detail("headers => $headers");
    $self->add_detail("$var_result => $method " . $self->rest_client->config_str . $path . "\n");
    $self->add_detail("JSON:\n$body_raw\n");

    my $body = $self->process_tt_value( 'JSON', $self->body, { between => ":\n", after => "\n" } );

    try {
        if ($headers) {
            $headers = $self->json2pl($headers);
        }
        else {
            undef $headers;
        }
    }
    catch {
        my $e = shift;
        die "Could not parse headers. ($e)";
    };

    my $response = $self->rest_client->request( $method, $path, $headers, $body );

    if ($check_success) {
        die $self->pl2str($response) . "\n"
          unless $response->{success};
    }

    return $response;
}

sub process {
    my ($self) = @_;

    my $var_result = $self->var_result;
    my $var_status = $self->var_status;

    try {
        my $response = $self->rest_request();

        $self->add_detail( "Status: $response->{status}" );
        $self->stash_set( $var_status => $response->{status} );

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
