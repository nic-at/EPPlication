package EPPlication::Client::SOAP;
use Moose;
use namespace::autoclean;
use Encode qw/ encode_utf8 /;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
extends 'EPPlication::HTTP::UA';

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    return $class->$orig(
        ua_options => [
            default_headers => {
                'Content-Type' => 'application/xml; charset=utf-8',
                'SOAPAction'   => 'urn:Registry::App::SOAP#command',
            },
        ],
        @_
    );
};

has 'path' => (
    is        => 'rw',
    isa       => NonEmptySimpleStr,
    predicate => 'has_path',
);

sub url {
    my ($self) = @_;
    return $self->host . ':' . $self->port . $self->path;
}

sub request {
    my ($self, $method, $content) = @_;

    for my $attr (qw/ host port path /) {
        my $predicate = "has_$attr";
        die "soap_$attr not configured.\n"
            unless $self->$predicate;
    }

    # 'ä' in path or query part are presented as
    # percent encoded bytes. e.g.: ä => %C3%A4
    my $uri = URI->new(encode_utf8($self->url));

    my $content_utf8 = encode_utf8($content);
    my $response = $self->ua->request(
        $method,
        $uri->as_string,
        { content => $content_utf8 },
    );

    $self->process_utf8_header($response);

    return $response;
}

__PACKAGE__->meta->make_immutable;

1;
