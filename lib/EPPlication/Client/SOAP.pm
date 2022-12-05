package EPPlication::Client::SOAP;
use Moose;
use namespace::autoclean;
use Encode qw/ encode_utf8 /;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
extends 'EPPlication::HTTP::UA';

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
    my ($self, $method, $headers, $content) = @_;

    for my $attr (qw/ host port path /) {
        my $predicate = "has_$attr";
        die "soap_$attr not configured.\n"
            unless $self->$predicate;
    }

    # 'ä' in path or query part are presented as
    # percent encoded bytes. e.g.: ä => %C3%A4
    my $uri = URI->new(encode_utf8($self->url));

    if ( defined $content ) {
        $content = encode_utf8($content);
    }

    my $request = HTTP::Request->new(
        $method,
        $uri->as_string,
        $headers,
        $content,
    );
    my $response =  $self->ua->request( $request );

    return $response;
}

__PACKAGE__->meta->make_immutable;

1;
