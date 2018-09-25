package EPPlication::Step::EPPConnect;

use Moose;
use EPPlication::Role::Step::Parameters;

with
    'EPPlication::Role::Step::Base',
    'EPPlication::Role::Step::Client::EPP',
    'EPPlication::Role::Step::Util::Encode',
    Parameters(parameter_list => [qw/ var_result host port ssl ssl_use_cert ssl_cert ssl_key /]),
    ;

sub process {
    my ($self) = @_;

    my $var_result = $self->var_result;

    for my $key (qw/ host port ssl ssl_use_cert ssl_cert ssl_key /) {
        my $value_raw = $self->$key;
        my $value     = $self->process_template($value_raw);
        $self->epp_client->$key($value);
    }

    $self->add_detail( 'Variable: ' . $var_result );
    $self->add_detail( 'Config:   ' . $self->epp_client->config_str );

    $self->epp_client->connect();

    my $response_xml = $self->epp_client->receive;
    $self->add_detail( "\nResponse:\n" . $response_xml );
    my $response_pl   = $self->xml2pl($response_xml);
    my $response_json = $self->pl2json($response_pl);
    $self->stash_set( $var_result => $response_json );
    $self->add_detail( "\nResponse:\n" . $self->pl2str($response_pl) );

    return $self->result;
}

__PACKAGE__->meta->make_immutable;
1;
