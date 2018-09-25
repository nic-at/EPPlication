package EPPlication::Step::VarQueryPath;

use Moose;
use Data::DPath::Path;
use EPPlication::Role::Step::Parameters;

with
  'EPPlication::Role::Step::Base',
  Parameters(parameter_list => [qw/ var_result input query_path /]),
  'EPPlication::Role::Step::Util::Encode',
  ;

sub process {
    my ($self) = @_;

    my $var_result = $self->var_result;
    $self->add_detail( 'Variable: ' . $var_result );

    my $input_raw = $self->input;
    my $input     = $self->process_template($input_raw);

    my $query_path = $self->process_tt_value( 'QueryPath', $self->query_path );

    my $input_pl = $self->json2pl($input);
    my $dpath    = Data::DPath::Path->new( path => $query_path );
    my @result   = $dpath->match($input_pl);

    my $num_results = scalar @result;
    if ( $num_results == 0 ) {
        $self->status('error');
        $self->add_detail("Node or Value does not exist.");
    }
    elsif ( $num_results == 1 ) {
        my $value = ref $result[0]
                    ? $self->pl2json( $result[0] )
                    : $result[0];

        # if the value is not defined replace with empty string
        $value = defined $value ? $value : '';

        $self->stash_set( $var_result => $value );
        $self->add_detail( $value );
    }
    else {
        my $value = $self->pl2json( \@result );
        $self->stash_set( $var_result => $value );
        $self->add_detail( $value );
    }

    return $self->result;
}

__PACKAGE__->meta->make_immutable;
1;
