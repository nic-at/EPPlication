package EPPlication::Step::Transformation::MibEPPClient;
use Moose;

sub transform {
    my ($self, $step, $var_result, $input) = @_;

    my $re = qr/
                 ^
                 (SUCCESS|ATTR|FAILED|Msg|Details|Messages\ waiting|message\ id|Queue-Date|message\ desc|message\ type)
                 :\ 
                 (.*)
                 $
             /xms;
    my $array = [];
    my @lines = split("\n", $input);
    my $count = 1;

    for my $line (@lines) {
        $count++;
        $line =~ s/\R//gxms;

        if ( my ($type, $val) = $line =~ $re ) {
            if ($type eq 'ATTR') {
                if ( my ($val1, $val2) = $val =~ qr/(\w+): \ (.*)$/xms ) {
                    push $array->@*, [$count, $type, $val1, $val2 // ''];
                    next;
                }
            }

            push $array->@*, [$count, $type, $val, ''];
        }
        else {
            push $array->@*, [$count, 'NONE', $line, ''];
        }
    }

    my $json = $step->pl2json($array);
    $step->stash_set( $var_result => $json );
    $step->add_detail( "Result:\n" . $step->pl2str($array) );
}

__PACKAGE__->meta->make_immutable;
1;
