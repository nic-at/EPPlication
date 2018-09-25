package EPPlication::Step::EPP;

use Moose;
use EPPlication::Role::Step::Parameters;
use Try::Tiny;

with
  'EPPlication::Role::Step::Base',
  Parameters(parameter_list => [qw/ body validate_xml var_result /]),
  'EPPlication::Role::Step::Client::EPP',
  'EPPlication::Role::Step::Util::Encode',
  ;

sub process {
    my ($self) = @_;

    my $var_result = $self->var_result;

    try {
        my $body_raw      = $self->body;
        my $validate_xml = $self->validate_xml;

        $self->add_detail( 'Variable: ' . $var_result );
        $self->add_detail( 'Validate XML: ' . $validate_xml );

        my $xml = $self->process_tt_value("Request XML", $self->body, { before => "\n\n", between => ":\n" });
        $self->epp_client->send( $xml, $validate_xml );

        my $response_xml = $self->epp_client->receive;
        $self->add_detail( "\n\nResponse XML:\n$response_xml" );
        my $response_pl   = $self->xml2pl($response_xml);
        my $response_json = $self->pl2json($response_pl);
        $self->stash_set( $var_result => $response_json );
        $self->add_detail( "\n\nResponse PL:\n" . $self->pl2str($response_pl) );

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
