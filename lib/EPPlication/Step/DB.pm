package EPPlication::Step::DB;

use Moose;
use EPPlication::Role::Step::Parameters;
use Try::Tiny;

with
  'EPPlication::Role::Step::Base',
  Parameters(parameter_list => [qw/ sql var_result /]),
  'EPPlication::Role::Step::Client::DB',
  'EPPlication::Role::Step::Util::Encode',
  ;

sub process {
    my ($self) = @_;

    my $var_result = $self->var_result;

    try {
        $self->add_detail( 'Variable: ' . $var_result );
        my $sql = $self->process_tt_value( 'SQL', $self->sql );

        my $response = $self->db_client->request($sql);

        my $response_type = ref $response;

        # if the statement was a SELECT statement we get a ARRAY reference of rows
        if ($response_type eq 'ARRAY') {
            $self->add_detail( "\nResponse PL:\n" . $self->pl2str($response) );

            my $response_json = $self->pl2json($response);
            $self->stash_set( $var_result => $response_json );
        }
        # otherwise the number of affected rows
        elsif ($response_type eq '') {
            $self->add_detail( "Rows affected: $response" );
            $self->stash_set( $var_result => $response );
        }
        else {
            die "Unknown response_type. ($response_type)";
        }

        return $self->result;
    }
    catch {
        my $e = shift;
        $self->stash_set( $var_result => q{} );
        die $e;
    };
}

__PACKAGE__->meta->make_immutable;
1;
