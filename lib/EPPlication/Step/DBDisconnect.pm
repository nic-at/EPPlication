package EPPlication::Step::DBDisconnect;

use Moose;
with qw/
    EPPlication::Role::Step::Base
    EPPlication::Role::Step::Client::DB
    /;

sub process {
    my ($self) = @_;

    $self->db_client->disconnect;

    return $self->result;
}

__PACKAGE__->meta->make_immutable;
1;
