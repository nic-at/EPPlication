package EPPlication::Role::Step::Parameters;

use strict;
use warnings;

use Package::Variant
    importing => ['Moose::Role'],
    subs      => [ qw/ requires has around before after with / ];

sub make_variant {
    my ( $class, $target_package, %arguments ) = @_;

    requires 'parameters';

    my $parameter_list = $arguments{parameter_list};

    for my $variable ( @$parameter_list ) {
        has "$variable" => (
            is       => 'ro',
            isa      => 'Str',
            lazy     => 1,
            init_arg => undef,
            builder  => "_build_$variable",
        );

        install "_build_$variable" => sub {
            my $self = shift;

            die "'$variable' not defined in parameters hashref"
                unless exists $self->parameters->{ $variable };
            return $self->parameters->{ $variable };
        };
    }
}

1;
