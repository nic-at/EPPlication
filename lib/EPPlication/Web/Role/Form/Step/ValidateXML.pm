package EPPlication::Web::Role::Form::Step::ValidateXML;
use HTML::FormHandler::Moose::Role;
use EPPlication::Web::Role::Form::Step::Boolean;
use Try::Tiny;
use XML::LibXML;
use namespace::autoclean;

with Boolean( name => 'validate_xml', default => 0 );

before 'validate' => sub {
    my ( $self ) = @_;

    return 1 unless $self->field('validate_xml')->value;

    my $xml = $self->field('body')->value;
    my $parser = XML::LibXML->new;
    try {
        $parser->parse_string($xml);
    }
    catch {
        my $e = shift;
        $self->field('body')->push_errors("Invalid XML ($e)");
    };
};

1;
