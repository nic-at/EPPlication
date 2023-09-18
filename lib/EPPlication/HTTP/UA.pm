package EPPlication::HTTP::UA;
use Moose;
use namespace::autoclean;
use MooseX::Types::Common::String qw/ NumericCode NonEmptySimpleStr /;
use LWP::UserAgent qw//;
use HTTP::Request;
use Encode qw/ decode_utf8 /;

has 'ua' => (
    is       => 'rw', # TODO: change back to 'ro' once LWP has a clear_credentials method
                      #       also replace $lwp->clone code from SOAP digest auth and use
                      #       clear_credentials instead.
    isa      => 'LWP::UserAgent',
    lazy     => 1,
    builder  => '_build_ua',
    init_arg => undef,
);
sub _build_ua {
    my ($self) = @_;
    return LWP::UserAgent->new( ssl_opts => {verify_hostname => 0}, %{ $self->ua_options },
    );
}
has 'ua_options' => (
    is        => 'ro',
    isa       => 'HashRef',
    default   => sub { {} },
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
    default   => '80',
);
has 'url_base' => (
    is       => 'ro',
    isa      => NonEmptySimpleStr,
    lazy     => 1,
    builder  => '_build_url_base',
    init_arg => undef,
);
sub _build_url_base {
    my ($self) = @_;
    return $self->host . ':' . $self->port
}
has 'api_base' => (
    is       => 'ro',
    isa      => NonEmptySimpleStr,
    lazy     => 1,
    builder  => '_build_api_base',
    init_arg => undef,
);
sub _build_api_base {
    my ($self) = @_;
    return $self->url_base . '/api';
}

__PACKAGE__->meta->make_immutable;
1;
