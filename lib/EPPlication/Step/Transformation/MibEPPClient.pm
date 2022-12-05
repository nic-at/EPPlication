package EPPlication::Step::Transformation::MibEPPClient;
use Moose;

sub transform {
    my ($self, $step, $var_result, $input) = @_;

    my $re = qr/
                 ^
                 (SUCCESS|ATTR|FAILED|Msg|Details)
                 :
                 \ 
                 ([-\w\ \[\]\(\)\{\}]+)
                 (?:
                     :
                     \ 
                     (.*)
                 )?
                 $
             /xms;
    my $array = [];
    my @lines = split("\n", $input);
    my $count = 1;

    for my $line (@lines) {
        $count++;
        $line =~ s/\R//gxms;

        if ( my ($type, $val1, $val2) = $line =~ $re ) {
            push $array->@*, [$count, $type, $val1, $val2 // ''];
        }
        else {
            push $array->@*, [$count, 'NONE', $line];
        }
    }

    my $json = $step->pl2json($array);
    $step->stash_set( $var_result => $json );
    $step->add_detail( "Result:\n" . $step->pl2str($array) );
}

__PACKAGE__->meta->make_immutable;
1;
