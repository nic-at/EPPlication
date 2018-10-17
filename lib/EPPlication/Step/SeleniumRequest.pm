package EPPlication::Step::SeleniumRequest;

use Moose;
use EPPlication::Role::Step::Parameters;
with
  'EPPlication::Role::Step::Base',
  'EPPlication::Role::Step::Client::Selenium',
  Parameters(parameter_list => [qw/ identifier url /]),
  ;

sub process {
    my ($self) = @_;

    my $identifier = $self->identifier;
    my $url        = $self->url;

    $self->add_detail("Requested page: $url");
    $self->add_detail("Driver identifier: $identifier");

    die "driver doesn't exist"
      if !$self->selenium_client->driver_exists($identifier);

    my $driver = $self->selenium_client->get_driver($identifier);
    $driver->get($url);

    return $self->result;
}

__PACKAGE__->meta->make_immutable;
1;
