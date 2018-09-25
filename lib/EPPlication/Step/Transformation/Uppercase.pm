package EPPlication::Step::Transformation::Uppercase;
use Moose;

sub transform {
    my ($self, $step, $var_result, $input) = @_;

    my $result = uc($input);
    $step->stash_set( $var_result => $result );
    $step->add_detail( $result );
}

__PACKAGE__->meta->make_immutable;
1;
