package EPPlication::Client::EPP;
use Moose;
use namespace::autoclean;
use Encode qw/ decode_utf8 encode_utf8 /;
use MooseX::Types::Common::String qw/ NumericCode NonEmptySimpleStr /;
use Net::EPP::Client;
use Net::SSLeay 1.21;
use constant SSL_VERIFY_NONE => Net::SSLeay::VERIFY_NONE();
use IO::Socket::SSL::Utils;

has 'client' => (
    is        => 'rw',
    isa       => 'Net::EPP::Client',
    predicate => 'has_client',
    handles   => {
        disconnect => 'disconnect',
    },
);

has 'host' => (
    is        => 'rw',
    isa       => NonEmptySimpleStr,
    predicate => 'has_host',
);
has 'port' => (
    is        => 'rw',
    isa       => NumericCode,
    predicate => 'has_port',
);
has 'ssl' => (
    is        => 'rw',
    isa       => NumericCode,
    predicate => 'has_ssl',
);
has 'ssl_use_cert' => (
    is        => 'rw',
    isa       => NumericCode,
    predicate => 'has_ssl_use_cert',
);
has 'ssl_cert' => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_ssl_cert',
);
has 'ssl_key' => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_ssl_key',
);

sub send {
    my ( $self, $xml, $wfcheck ) = @_;

    $wfcheck = defined $wfcheck ? $wfcheck : 1;

    die "EPP client not connected.\n"
      unless $self->connected;

    $xml = encode_utf8($xml);
    $self->client->send_frame($xml, $wfcheck);
}

sub receive {
    my ($self) = @_;

    die "EPP client not connected.\n"
      unless $self->connected;

    my $xml_raw = $self->client->get_frame();
    my $xml     = decode_utf8($xml_raw);
    return $xml;
}

sub config_str {
    my ($self) = @_;
    return $self->host . ':' . $self->port
      . ' (ssl => ' . $self->ssl
      . ', ssl_use_cert => ' . $self->ssl_use_cert . ')';
}

sub connect {
    my ($self) = @_;

    die "EPP client already connected.\n"
        if $self->connected;

    for my $attr (qw/ host port ssl ssl_use_cert ssl_cert ssl_key /) {
        my $predicate = "has_$attr";
        die "epp_$attr not configured.\n"
            unless $self->$predicate;
    }

    # NOTE: Net::EPP::Client is weird because its ssl param
    # must be undefined for ssl to be turned off.
    my $ssl = $self->ssl eq '1' ? 1 : undef;

    my %connect_params = (
        no_greeting     => 1,
        SSL_verify_mode => SSL_VERIFY_NONE,
        $self->ssl_use_cert
        ? (
            SSL_use_cert    => 1,
            SSL_cert => IO::Socket::SSL::Utils::PEM_string2cert( $self->ssl_cert ),
            SSL_key => IO::Socket::SSL::Utils::PEM_string2key( $self->ssl_key ),
          )
        : (),
    );

    my $client = Net::EPP::Client->new(
        host => $self->host,
        port => $self->port,
        ssl  => $ssl,
    );

    $client->connect( %connect_params );
    $self->client($client);
}

sub connected {
    my ($self) = @_;
    return unless $self->has_client;
    return $self->client->connected;
}

__PACKAGE__->meta->make_immutable;
1;
