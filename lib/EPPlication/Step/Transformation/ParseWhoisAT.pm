package EPPlication::Step::Transformation::ParseWhoisAT;
use Moose;

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
    my ($object, $key, $val, $last_key, $last_val) = @_;
    if ($key eq 'nserver') {
        # only store hostname once
        push @{ $object->{nserver}{$val}{hostname} }, $val
            unless defined $object->{nserver}{$val}{hostname};
    }
    elsif ( $key eq 'remarks' ) {
        if ($last_key ne 'nserver') {
            die "'remarks' found but last line wasn't 'nserver'. ($key: $val)";
        }
        my $ip_version;
        if ($val =~ /^\d+\.\d+\.\d+\.\d+$/) {
            $ip_version = 'ipv4';
        }
        elsif ($val =~ /^[0-9A-Fa-f]+[0-9A-Fa-f:]+[0-9A-Fa-f]+$/) {
            $ip_version = 'ipv6';
        }
        else {
            die "invalid line ($key: $val)";
        }
        push @{ $object->{nserver}{$last_val}{$ip_version} }, $val;
    }
    else {
        push @{ $object->{$key} }, $val;
    }
}

sub transform {
    my ($self, $step, $var_result, $input) = @_;

    my $pl = [];
    my $last_key = '';
    my $last_val = '';
    my $object;
    for my $line ( split( /\n/, $input ) ) {
        if ( $line =~ /^%/ ) {    # ignore comments
            next;
        }
        elsif ( $line =~ /^\s*$/ ) {    # an empty line finalizes a block
            if ( defined $object ) {
                push( @$pl, $object );
                undef $object;
            }
            $last_key = '';
            $last_val = '';
            next;
        }
        else {                     # process key/value line
            my ( $key, $val ) = _parse_line($line);

            if ( !defined $object ) {
                if ( $key ne 'domain' && $key ne 'personname' ) {
                    die "Unknown object type: $key";
                }
                $object = {};
            }

            _add_attr( $object, $key, $val, $last_key, $last_val );
            $last_key = $key;
            $last_val = $val;
        }
    }
    push(@$pl, $object) if defined $object;
    $step->add_detail( "Result:\n" . $step->pl2str($pl) );
    my $json = $step->pl2json($pl);
    $step->stash_set( $var_result => $json );
}

__PACKAGE__->meta->make_immutable;
1;
