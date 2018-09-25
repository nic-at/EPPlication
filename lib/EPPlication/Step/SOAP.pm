package EPPlication::Step::SOAP;

use Moose;
use EPPlication::Role::Step::Parameters;
use Try::Tiny;

with
  'EPPlication::Role::Step::Base',
  Parameters(parameter_list => [qw/ host port path method body var_result /]),
  'EPPlication::Role::Step::Client::SOAP',
  'EPPlication::Role::Step::Util::Encode',
  ;

sub process {
    my ($self) = @_;

    my $var_result = $self->var_result;

    try {
        my $method  = $self->method;

        for my $config (qw/ host port path /) {
            my $value_raw = $self->$config;
            my $value     = $self->process_template($value_raw);
            $self->soap_client->$config($value);
        }
        $self->add_detail($method . ' ' . $self->soap_client->url);

        $self->add_detail("Variable: $var_result");
        my $xml = $self->process_tt_value( 'Request XML', $self->body, { before => "\n", between => ":\n" } );

        my $response = $self->soap_client->request($method, $xml);
	die $self->pl2str($response) unless $response->{success};

        my $response_xml = $self->str2xml_str( $response->{content} );
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
