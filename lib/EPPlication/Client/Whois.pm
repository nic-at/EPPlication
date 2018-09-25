package EPPlication::Client::Whois;
use Moose;
use namespace::autoclean;
use Encode qw/ encode_utf8 /;
use Net::Whois::Raw;

sub request {
    my ($self, $host, $port, $domain) = @_;

    # 'ä' in path or query part are presented as
    # percent encoded bytes. e.g.: ä => %C3%A4
    my $domain_utf8 = encode_utf8($domain);

    my ( $response, $srv ) = get_whois( $domain_utf8, "$host:$port" );

    return wantarray ? ($response, $srv) : $response;
}

__PACKAGE__->meta->make_immutable;
1;
