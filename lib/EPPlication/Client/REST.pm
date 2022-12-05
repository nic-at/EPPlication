package EPPlication::Client::REST;
use Moose;
use namespace::autoclean;
use URI;
use Encode qw/ encode_utf8 /;
use MooseX::Types::Common::String qw/ NonEmptySimpleStr /;
extends 'EPPlication::HTTP::UA';

sub url {
    my ($self) = @_;
    return $self->host . ':' . $self->port;
}

sub config_str {
    my ($self) = @_;
    return $self->url;
}

sub request {
    my ($self, $method, $path, $headers, $content) = @_;

    for my $attr (qw/ host port /) {
        my $predicate = "has_$attr";
        die "rest_$attr not configured.\n"
            unless $self->$predicate;
    }

    # 'ä' in path or query part are presented as
    # percent encoded bytes. e.g.: ä => %C3%A4
    my $uri = URI->new(encode_utf8($self->url . $path));

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
