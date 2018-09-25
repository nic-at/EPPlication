package EPPlication::Step::Comment;

use Moose;
use EPPlication::Role::Step::Parameters;

with
  'EPPlication::Role::Step::Base',
  Parameters(parameter_list => [qw/ comment /]),
  ;

sub process {
    my ($self) = @_;

    $self->add_detail( $self->comment );
    return $self->result;
}

__PACKAGE__->meta->make_immutable;
1;
