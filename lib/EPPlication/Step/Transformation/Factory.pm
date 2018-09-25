package EPPlication::Step::Transformation::Factory;

use Moose;
use List::Util qw/none/;

use Module::Pluggable
    sub_name    => '_plugins',
    search_path => 'EPPlication::Step::Transformation',
    require     => 1,
    except      => [ 'EPPlication::Step::Transformation::Factory' ];

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
    my ( $self, $type ) = @_;

    die "Can't create Transformation without type."
      unless (defined $type);
    my $class = 'EPPlication::Step::Transformation::' . $type;
    die "Unknown transformation type: $type"
      if none { $_ eq $class } @{ $self->plugins };

    return $class->new();
}

__PACKAGE__->meta->make_immutable;
1;
