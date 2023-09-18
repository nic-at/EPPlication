package EPPlication::Step::SeleniumConnect;

use Moose;
use EPPlication::Role::Step::Parameters;
use Selenium::Firefox;
use Selenium::Remote::WDKeys;

with
  'EPPlication::Role::Step::Base',
  'EPPlication::Role::Step::Client::Selenium',
  Parameters(parameter_list => [qw/ identifier host port global /]),
  ;

sub process {
    my ($self) = @_;

    my %conf = ();
    for my $key (qw/ identifier host port /) {
        my $value_raw = $self->$key;
        my $value     = $self->process_template($value_raw);
        $conf{$key} = $value;
    }

    $self->add_detail('Create new driver');
    $self->add_detail('Identifier: ' . $conf{identifier});

    die 'driver exists'
      if $self->selenium_client->driver_exists($conf{identifier});

    my $driver = Selenium::Firefox->new(
        remote_server_addr => $conf{host},
        port => $conf{port},
    );
    $self->selenium_client->set_driver($conf{identifier} => $driver);
    $self->add_detail('Available drivers:');
    for my $driver (keys %{$self->selenium_client->drivers}) {
        $self->add_detail(' '.$driver);
    }

    return $self->result;
}

__PACKAGE__->meta->make_immutable;
1;
