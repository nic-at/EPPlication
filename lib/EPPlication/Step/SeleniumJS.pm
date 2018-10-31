package EPPlication::Step::SeleniumJS;

use Moose;
use EPPlication::Role::Step::Parameters;
with
  'EPPlication::Role::Step::Base',
  'EPPlication::Role::Step::Client::Selenium',
  Parameters(parameter_list => [qw/ identifier javascript /]),
  ;

sub process {
    my ($self) = @_;

    my %conf = ();
    for my $key (qw/ identifier javascript /) {
        my $value_raw = $self->$key;
        my $value     = $self->process_template($value_raw);
        $conf{$key} = $value;
    }
    my $identifier = $conf{identifier};
    my $javascript = $conf{javascript};

    $self->add_detail("Driver identifier: $identifier");

    die "driver doesn't exist"
      if !$self->selenium_client->driver_exists($identifier);

    my $driver = $self->selenium_client->get_driver($identifier);
    $driver->execute_script($javascript);

    return $self->result;
}

__PACKAGE__->meta->make_immutable;
1;
