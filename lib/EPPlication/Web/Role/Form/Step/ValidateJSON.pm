package EPPlication::Web::Role::Form::Step::ValidateJSON;
use HTML::FormHandler::Moose::Role;
use EPPlication::Web::Role::Form::Step::Boolean;
use Try::Tiny;
use JSON::PP qw//;
use namespace::autoclean;

with Boolean( name => 'validate_json', default => 0 );

before 'validate' => sub {
    my ( $self ) = @_;

    return 1 unless $self->field('validate_json')->value;

    my $json = $self->field('body')->value;
    try {
        JSON::PP->new->decode($json);
    }
    catch {
        my $e = shift;
        $self->field('body')->push_errors("Invalid JSON ($e)");
    };
};

1;
