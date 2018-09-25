package EPPlication::Step::ClearVars;

use Moose;
with 'EPPlication::Role::Step::Base';

sub process {
    my ($self) = @_;

    $self->add_detail( 'Clearing all variables.' );
    $self->stash_clear;

    return $self->result;
}

__PACKAGE__->meta->make_immutable;
1;
