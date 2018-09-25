package EPPlication::Step::CountQueryPath;

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

    my $input_raw = $self->input;
    my $input     = $self->process_template($input_raw);

    $self->add_detail( "var_result: " . $var_result );
    my $query_path = $self->process_tt_value( 'QueryPath', $self->query_path );

    my $input_pl = $self->json2pl($input);
    my $dpath    = Data::DPath::Path->new( path => $query_path );
    my @result   = $dpath->match($input_pl);
    my $count    = scalar @result;
    $self->stash_set( $var_result => $count );
    $self->add_detail( "Count: $count\n\n" . $self->pl2str( \@result ) );

    return $self->result;
}

__PACKAGE__->meta->make_immutable;
1;
