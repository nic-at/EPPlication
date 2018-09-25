package EPPlication::Step::Factory;

use Moose;
use List::Util qw/none/;

use Module::Pluggable
    sub_name    => '_plugins',
    search_path => 'EPPlication::Step',
    require     => 1,
    except      => [ 'EPPlication::Step::Factory' ];

has 'plugins' => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub {
        my $self = shift;
        # it is important that this attribute is not lazy
        # because calling 'plugins()' requires the modules
        return [ $self->_plugins ];
    },
);

sub create {
    my ( $self, $data ) = @_;

    die "Can't create Step without type."
      unless (defined $data && defined $data->{type});
    my $class = 'EPPlication::Step::' . $data->{type};
    die "Unknown step type: $data->{type}"
      if none { $_ eq $class } @{ $self->plugins };
    return $class->new( %$data );
}

__PACKAGE__->meta->make_immutable;
1;
