package EPPlication::Role::Step::Util::Encode;
use Moose::Role;

use Try::Tiny;
use Text::CSV;
use XML::LibXML;
use XML::LibXML::Simple qw/ XMLin /;
use Encode qw/ decode_utf8 /;
use JSON::PP qw//;
$JSON::PP::true  = 1;
$JSON::PP::false = 0;
use Data::Printer {
    return_value   => 'dump',
    indent         => 2,
    hash_separator => ' => ',
    index          => 0,
    colored        => 0,
    show_dualvar   => 'off',
};

sub str2xml_str {
    my ( $self, $str ) = @_;
    my $xml     = XML::LibXML->new->parse_string($str);
    my $xml_str = decode_utf8( $xml->toString(1) );
    return $xml_str;
}

sub xml2pl {
    my ($self, $xml) = @_;

    my %config = (
        KeepRoot   => 1,
        ForceArray => 0,
        KeyAttr    => undef,
    );
    my $xs = XML::LibXML::Simple->new( %config );
    my $pl = $xs->XMLin( $xml );
    return $pl;
}

sub json2pl {
    my ($self, $str) = @_;
    try {
        return JSON::PP->new->decode($str);
    }
    catch {
        my $e = shift;
        die "json2pl failed.\n\nJSON string:\n$str\n\n$e";
    };
}

sub pl2json {
    my ($self, $pl) = @_;
    try {
        return JSON::PP->new->encode($pl);
    }
    catch {
        my $e = shift;
        die "pl2json failed.\n\n" . $self->pl2str($pl) . "\n\n$e";
    };
}

sub pl2str {
    my ($self, $pl) = @_;
    my $str = p($pl);
    return $str;
}

sub csv2pl {
    my ($self, $csv, $sep_char, $quote_char) = @_;
    try {
        my @rows = split("\n", $csv);
        my $csv = Text::CSV->new({ sep_char => $sep_char, quote_char => $quote_char });
        my @pl = ();
        for my $row (@rows) {
            $csv->parse($row);
            push(@pl, [ $csv->fields() ]);
        }
        return \@pl;
    }
    catch {
        my $e = shift;
        die "csv2json failed.\n\n" . $csv . "\n\n$e";
    };
}

1;
