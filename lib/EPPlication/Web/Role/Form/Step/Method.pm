package EPPlication::Web::Role::Form::Step::Method;
use HTML::FormHandler::Moose::Role;
use List::Util qw/ any /;
use namespace::autoclean;

has_field 'method' => (
    type         => 'Text',
    required     => 1,
    noupdate     => 1,
    not_nullable => 1,
);

sub validate_method {
    my ( $self, $field ) = @_;
    my $v = $field->value;

    return if ($v =~ m/^\[%.*%\]$/xms);
    return if ( any { $_ eq $v } qw/GET POST PUT DELETE HEAD OPTIONS/ );
    $field->push_errors("Invalid method ($v)\n");
}

around '_build_parameter_fields' => sub {
    my ($orig, $self) = @_;
    return [ @{ $self->$orig }, 'method' ];
};

1;
