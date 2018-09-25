package EPPlication::Step::Transformation::ParseWhoisBox;
use Moose;
use List::Util qw/ any /;

sub _parse_line {
    my ($line) = @_;

    my $index = index($line, ':');
    if ($index == -1) {
        die "Couldn't parse line. ($line)\n";
    }
    else {
        my $key = substr($line, 0, $index);
        my $val = substr($line, $index+1);
        $key =~ s/^\s+|\s+$//g; #trim
        $val =~ s/^\s+|\s+$//g; #trim
        return ($key, $val);
    }
}

sub _add_attr {
    my ($block, $key, $val) = @_;
    push( @{ $block->{$key} }, $val );
}

sub transform {
    my ($self, $step, $var_result, $input) = @_;

    my $pl                = [];
    my $global_block      = {};
    my $block;
    my $last_block_id     = '';

    for my $line ( split( /\n/, $input ) ) {
        next if ( $line =~ /^%/ );       # ignore comments
        next if ( $line =~ /^\s*$/ );    # ignore empty lines
        my ( $key, $val ) = _parse_line($line);

        if ( $key =~ m/^Registry\ (Registrant|Admin|Tech)\ ID$/xms ) {
            $last_block_id = $1;                    # remember block identifier
            push( @$pl, $block ) if defined $block; # finalize previous block
            $block = {};                            # init new block
            _add_attr( $block, $key, $val );
        }
        elsif ( $key =~ m/^(Registrant|Admin|Tech)\ (?:.*)$/xms ) {
            my $block_id = $1;
            if ( $block_id ne $last_block_id ) {
                die "Block must start with ID line. ($line)";
            }
            _add_attr( $block, $key, $val );
        }
        else {
            _add_attr( $global_block, $key, $val );
        }
    }

    push(@$pl, $block) if defined $block;
    unshift(@$pl, $global_block);

    $step->add_detail( "Result:\n" . $step->pl2str($pl) );
    my $json = $step->pl2json($pl);
    $step->stash_set( $var_result => $json );
}

__PACKAGE__->meta->make_immutable;
1;
