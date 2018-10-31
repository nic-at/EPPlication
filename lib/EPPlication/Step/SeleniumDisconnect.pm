package EPPlication::Step::SeleniumDisconnect;

use Moose;
use EPPlication::Role::Step::Parameters;
with
  'EPPlication::Role::Step::Base',
  'EPPlication::Role::Step::Client::Selenium',
  Parameters(parameter_list => [qw/ identifier /]),
  ;

sub process {
    my ($self) = @_;

    my $identifier_raw = $self->identifier;
    my $identifier = $self->process_template($identifier_raw);

    $self->add_detail("Driver identifier: $identifier");

    die "driver doesn't exist"
      if !$self->selenium_client->driver_exists($identifier);

    $self->selenium_client->get_driver($identifier)->quit;
    $self->selenium_client->delete_driver($identifier);

    return $self->result;
}

__PACKAGE__->meta->make_immutable;
1;
