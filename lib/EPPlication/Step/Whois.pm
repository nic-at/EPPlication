package EPPlication::Step::Whois;

use Moose;
use Try::Tiny;
use EPPlication::Role::Step::Parameters;

with
  'EPPlication::Role::Step::Base',
  'EPPlication::Role::Step::Client::Whois',
  Parameters( parameter_list => [qw/ var_result host port domain /] ),
  ;

sub process {
    my ($self) = @_;

    my $var_result = $self->var_result;
    my $host_raw   = $self->host;
    my $host       = $self->process_template($host_raw);
    my $port_raw   = $self->port;
    my $port       = $self->process_template($port_raw);
    my $domain_raw = $self->domain;
    my $domain     = $self->process_template($domain_raw);

    $self->add_detail("host: $host");
    $self->add_detail("port: $port");
    $self->add_detail("domain: $domain");

    try {
        my ( $response, $srv ) = $self->whois_client->request( $host, $port, $domain );

        $self->add_detail("\nResponse from: $srv");
        $self->add_detail( "\n" . $response );
        $self->stash_set( $var_result => $response );
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
