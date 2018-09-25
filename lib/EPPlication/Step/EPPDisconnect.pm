package EPPlication::Step::EPPDisconnect;

use Moose;

with qw/
    EPPlication::Role::Step::Base
    EPPlication::Role::Step::Client::EPP
    /;

sub process {
    my ($self) = @_;

    $self->epp_client->disconnect;

    return $self->result;
}

__PACKAGE__->meta->make_immutable;
1;
