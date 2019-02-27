package EPPlication::Step::Transformation::Xml2Json;
use Moose;

sub transform {
    my ($self, $step, $var_result, $input) = @_;

    my $xml_str = $step->str2xml_str($input);
    my $pl      = $step->xml2pl($xml_str);
    $step->add_detail( "Result:\n" . $step->pl2str($pl) );
    my $json = $step->pl2json($pl);
    $step->stash_set( $var_result => $json );
}

__PACKAGE__->meta->make_immutable;
1;
