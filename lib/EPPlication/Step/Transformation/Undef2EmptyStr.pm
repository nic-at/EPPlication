package EPPlication::Step::Transformation::Undef2EmptyStr;
use Moose;

sub transform {
    my ($self, $step, $var_result, $input) = @_;

    my $input_pl  = $step->json2pl($input);
    my @stack = ();
    push(@stack, $input_pl) if ref $input_pl;

    # iterate over input datastructure and replace every
    # undefined hash-value with an empty-string (undef => '')
    while ( my $ref = pop(@stack) ) {
        if (ref $ref eq 'HASH') {
            for my $key (keys %$ref) {
                if (defined $ref->{$key}) {
                    push(@stack, $ref->{$key}) if ref $ref->{$key};
                }
                else {
                    $ref->{$key} = q//;
                }
            }
        }
        elsif (ref $ref eq 'ARRAY') {
            push(@stack, grep { ref $_ } @$ref);
        }
    }

    my $result = $step->pl2json($input_pl);
    $step->stash_set( $var_result => $result );
    $step->add_detail( "Result:\n" . $step->pl2str($input_pl) );
}

__PACKAGE__->meta->make_immutable;
1;
