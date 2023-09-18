package EPPlication::Step::SOAP;

use Moose;
use EPPlication::Role::Step::Parameters;
use Try::Tiny;

with
  'EPPlication::Role::Step::Base',
  Parameters(parameter_list => [qw/ host port path method body headers var_result http_digest check_success/]),
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
        my $http_digest_raw = $self->http_digest;
        my $http_digest_str = $self->process_template($http_digest_raw);
        my $check_success = $self->check_success;

        for my $config (qw/ host port path /) {
            my $value_raw = $self->$config;
            my $value     = $self->process_template($value_raw);
            $self->soap_client->$config($value);
        }

        $self->add_detail("$var_result => $method " . $self->soap_client->url);
        $self->add_detail("headers => $headers");
        $self->add_detail("check_success => $check_success");

        my $http_digest;
        my $ua_clone;
        if ($http_digest_str) {
            try {
                $http_digest = $self->json2pl($http_digest_str);
                die 'digest is not an arrayref' unless ref $http_digest eq 'ARRAY';
                die 'digest must have 4 items' unless scalar $http_digest->@* == 4;
                $ua_clone = $self->soap_client->ua->clone();
                $self->soap_client->ua->credentials($http_digest->@*);
                my $creds = '' . $self->soap_client->ua->credentials($http_digest->[0], $http_digest->[1]);
                $self->add_detail( "Digest: " . $creds );
            }
            catch {
                my $e = shift;
                die "could not parse http_digest. ($e)";
            };
        }

        my $xml = $self->process_tt_value(
            'Request XML',
            $self->body,
            { before => "\n", between => ":\n", after => "\n" }
        );

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

        # reset LWP::UA after we have set credentials
        $self->soap_client->ua($ua_clone)
            if $ua_clone;

        if (!$response->is_success && $check_success) {
	    die $response->as_string . "\n";
        }

        my $content = $response->decoded_content;
        if ($response->header('Content-Type') =~ m!/(?:[a-z]+\+)?xml!xms) {
            my $response_xml = $self->str2xml_str( $response->decoded_content );
            $self->add_detail( "\nResponse XML:\n$response_xml" );
            my $response_pl   = $self->xml2pl($response_xml);
            my $response_json = $self->pl2json($response_pl);
            $self->stash_set( $var_result => $response_json );
            $self->add_detail( "Response PL:\n" . $self->pl2str($response_pl) );
        }
        else {
            $self->add_detail( "Response:\n" . ($content) );
            $self->stash_set( $var_result => $content );
        }

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
