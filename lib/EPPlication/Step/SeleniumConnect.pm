package EPPlication::Step::SeleniumConnect;

use Moose;
use EPPlication::Role::Step::Parameters;
use Selenium::Remote::Driver;
use Selenium::Remote::WDKeys;

with
  'EPPlication::Role::Step::Base',
  'EPPlication::Role::Step::Client::Selenium',
  Parameters(parameter_list => [qw/ identifier host port global /]),
  ;

sub process {
    my ($self) = @_;

    my $identifier = $self->identifier;
    my $host       = $self->host;
    my $port       = $self->port;

    $self->add_detail('Create new driver');
    $self->add_detail('Identifier: ' . $identifier);

    die 'driver exists'
      if $self->selenium_client->driver_exists($identifier);

    my $driver = Selenium::Remote::Driver->new(
        remote_server_addr => $host,
        port => $port,
    );
    $self->selenium_client->set_driver($identifier => $driver);
    $self->add_detail('Available drivers:');
    for my $driver (keys %{$self->selenium_client->drivers}) {
        $self->add_detail(' '.$driver);
    }

    return $self->result;
}

__PACKAGE__->meta->make_immutable;
1;
