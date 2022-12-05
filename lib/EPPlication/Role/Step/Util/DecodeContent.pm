package EPPlication::Role::Step::Util::DecodeContent;
use Moose::Role;

use Encode qw/ decode_utf8 /;
use Try::Tiny;
with 'EPPlication::Role::Step::Util::Encode';

sub decode_content {
    my ( $self, $response, $var_result ) = @_;

    my $content = $response->decoded_content(charset => 'none');
    if ($response->content_charset eq 'UTF-8') {
        $content = decode_utf8( $content );
    }

    if ( $content eq '' ) {
        $self->stash_set( $var_result => '' );
        $self->add_detail("Response content was empty.");
    }
    elsif ( $response->header('content-type') ) {
        my $content_type = lc( $response->header('content-type') );
        if ( $content_type =~ m!application/(?:\w+\+)?json!xms ) {

            # JSON
            $self->stash_set( $var_result => $content );
            $self->add_detail("Response JSON:\n$content");
            my $content_pl = $self->json2pl($content);
            $self->add_detail(
                "Response PL:\n" . $self->pl2str($content_pl) );
        }
        elsif ( $content_type =~ m!text/csv!xms ) {

            # CSV
            my ( $sep_char_hex, $quote_char_hex )
                = _parse_csv_chars($content_type);
            $self->add_detail("sep_char: 0x$sep_char_hex");
            my $sep_char = chr( hex($sep_char_hex) );
            $self->add_detail("quote_char: 0x$quote_char_hex");
            my $quote_char = chr( hex($quote_char_hex) );

            $self->add_detail("\nResponse CSV:\n$content");
            my $content_pl
                = $self->csv2pl( $content, $sep_char, $quote_char );
            my $content_json = $self->pl2json($content_pl);
            $self->stash_set( $var_result => $content_json );
            $self->add_detail(
                "Response PL:\n" . $self->pl2str($content_pl) );
        }
        else {
            $self->stash_set( $var_result => $content );
            $self->add_detail( "Response Content:\n" . $content );
        }
    }
}

sub _parse_csv_chars {
    my ($content_type) = @_;

    my $sep_char_hex   = '2c'; # 2c => ,
    my $quote_char_hex = '22'; # 22 => "

    my $sep_prefix = 'separator=0x';
    my $sep_index = index( $content_type, $sep_prefix );
    if ( $sep_index != -1 ) {
        $sep_char_hex =
          substr( $content_type, $sep_index + length($sep_prefix), 2 );
    }

    my $quote_prefix = 'quotechar=0x';
    my $quote_index = index( $content_type, $quote_prefix );
    if ( $quote_index != -1 ) {
        $quote_char_hex =
          substr( $content_type, $quote_index + length($quote_prefix), 2 );
    }

    return ($sep_char_hex, $quote_char_hex);
}

1;
