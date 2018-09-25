package EPPlication::Step::DBConnect;
use Moose;
use EPPlication::Role::Step::Parameters;

with
  'EPPlication::Role::Step::Base',
  'EPPlication::Role::Step::Client::DB',
  Parameters( parameter_list => [qw/ host port database username password /] ),
  ;

sub process {
    my ($self) = @_;

    for my $config (qw/ host port database username password /) {
        my $value_raw = $self->$config;
        my $value     = $self->process_template($value_raw);
        $self->db_client->$config($value);
    }

    $self->add_detail( $self->db_client->config_str );
    $self->db_client->connect();

    return $self->result;
}

__PACKAGE__->meta->make_immutable;
1;
