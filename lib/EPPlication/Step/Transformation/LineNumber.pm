package EPPlication::Step::Transformation::LineNumber;
use Moose;

sub transform {
    my ($self, $step, $var_result, $input) = @_;

    my $maxlinenum = $input =~ tr/\n//;
    my $padding = length($maxlinenum);
    my $linenum = 1;
    my $result = '';
    open(my $fh, '<', \$input) or die $!;
    while (<$fh>) {
      $result .= sprintf("%0${padding}d", $linenum++) . " $_";
    }
    close $fh or die $!;
    $step->stash_set( $var_result => $result );
    $step->add_detail( $result );
}

__PACKAGE__->meta->make_immutable;
1;
