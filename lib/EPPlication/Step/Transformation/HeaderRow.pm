package EPPlication::Step::Transformation::HeaderRow;
use Moose;

sub transform {
    my ($self, $step, $var_result, $input) = @_;

    my $result_pl  = $step->json2pl($input);
    my $headers    = delete $result_pl->{headers};
    my $rows       = delete $result_pl->{rows};
    $result_pl->{headers_rows} = _create_header_row( $headers, $rows );
    my $result     = $step->pl2json($result_pl);
    $step->stash_set( $var_result => $result );
    $step->add_detail( "Result:\n" . $step->pl2str($result_pl) );
}

sub _create_header_row {
    my ($headers, $rows) = @_;

    my @header_row_array;
    for my $row (@$rows) {
        die "headers and rows array differ in size."
          if ( scalar @$headers != scalar @$row );
        push( @header_row_array,
            { map { $headers->[$_] => $row->[$_] } 0 .. scalar @$headers - 1 }
        );
    }
    return \@header_row_array;
}

__PACKAGE__->meta->make_immutable;
1;
