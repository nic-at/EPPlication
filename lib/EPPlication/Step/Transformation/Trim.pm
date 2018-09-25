package EPPlication::Step::Transformation::Trim;
use Moose;

sub transform {
    my ($self, $step, $var_result, $input) = @_;

    my $result = $input;
    $result =~ s/^\s+|\s+$//g;
    $step->stash_set( $var_result => $result );
    $step->add_detail( $result );
}

__PACKAGE__->meta->make_immutable;
1;
