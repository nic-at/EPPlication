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

    my %conf = ();
    for my $key (qw/ identifier url /) {
        my $value_raw = $self->$key;
        my $value     = $self->process_template($value_raw);
        $conf{$key} = $value;
    }
    my $identifier = $conf{identifier};
    my $url        = $conf{url};

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
