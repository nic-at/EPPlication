package EPPlication::HTTP::UA;
use Moose;
use namespace::autoclean;
use MooseX::Types::Common::String qw/ NumericCode NonEmptySimpleStr /;
use HTTP::Tiny;
use Encode qw/ decode_utf8 /;

has 'ua' => (
    is       => 'ro',
    isa      => 'HTTP::Tiny',
    lazy     => 1,
    builder  => '_build_ua',
    init_arg => undef,
);
sub _build_ua {
    my ($self) = @_;
    return HTTP::Tiny->new( @{ $self->ua_options } );
}
has 'ua_options' => (
    is        => 'ro',
    isa       => 'ArrayRef',
    default   => sub { [] },
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

sub process_utf8_header {
    my ( $self, $response ) = @_;
    if ( exists $response->{headers}{'content-type'} ) {
        my $content_type = lc( $response->{headers}{'content-type'} );
        if ( $content_type =~ m/charset=utf-8/xms ) {
            $response->{content} = decode_utf8( $response->{content} );
        }
    }
}

__PACKAGE__->meta->make_immutable;
1;
