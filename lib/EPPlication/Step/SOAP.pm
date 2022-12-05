package EPPlication::Step::SOAP;

use Moose;
use EPPlication::Role::Step::Parameters;
use Try::Tiny;

with
  'EPPlication::Role::Step::Base',
  Parameters(parameter_list => [qw/ host port path method body headers var_result /]),
  'EPPlication::Role::Step::Client::SOAP',
  'EPPlication::Role::Step::Util::Encode',
  ;

sub process {
    my ($self) = @_;

    my $var_result = $self->var_result;

    try {
        my $method      = $self->method;
        my $headers_raw = $self->headers;
        my $headers     = $self->process_template($headers_raw);

        for my $config (qw/ host port path /) {
            my $value_raw = $self->$config;
            my $value     = $self->process_template($value_raw);
            $self->soap_client->$config($value);
        }

        $self->add_detail("$var_result => $method " . $self->soap_client->url);
        $self->add_detail("headers => $headers");

        my $xml = $self->process_tt_value( 'Request XML', $self->body, { before => "\n", between => ":\n" } );

        if ($headers) {
            try {
                $headers = $self->json2pl($headers);
            }
            catch {
                my $e = shift;
                die "could not parse headers. ($e)";
            };
        }

        my $response = $self->soap_client->request($method, $headers, $xml);
	die $response->as_string unless $response->is_success;

        my $response_xml = $self->str2xml_str( $response->decoded_content );
        $self->add_detail( "\nResponse XML:\n$response_xml" );
        my $response_pl   = $self->xml2pl($response_xml);
        my $response_json = $self->pl2json($response_pl);
        $self->stash_set( $var_result => $response_json );
        $self->add_detail( "Response PL:\n" . $self->pl2str($response_pl) );

        return $self->result;
    }
    catch {
        my $e = shift;
        $self->stash_set( $var_result => q{} );
        die $e;
    };
}

__PACKAGE__->meta->make_immutable;
1;
