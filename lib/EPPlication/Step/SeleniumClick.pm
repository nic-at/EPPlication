package EPPlication::Step::SeleniumClick;

use Moose;
use EPPlication::Role::Step::Parameters;
with
  'EPPlication::Role::Step::Base',
  'EPPlication::Role::Step::Client::Selenium',
  Parameters(parameter_list => [qw/ identifier locator selector input /]),
  ;

sub process {
    my ($self) = @_;

    my %conf = ();
    for my $key (qw/ identifier locator selector /) {
        my $value_raw = $self->$key;
        my $value     = $self->process_template($value_raw);
        $conf{$key} = $value;
    }
    my $identifier = $conf{identifier};
    my $locator    = $conf{locator};
    my $selector   = $conf{selector};

    $self->add_detail("Driver identifier: $identifier");
    $self->add_detail('Locator: ' . $locator);
    $self->add_detail('Selector: ' . $selector);

    die "driver doesn't exist"
      if !$self->selenium_client->driver_exists($identifier);

    my $driver = $self->selenium_client->get_driver($identifier);
    my $locator_sub = 'find_element_by_' . $locator;
    my $el = $driver->$locator_sub($selector);
    $el->click();

    return $self->result;
}

__PACKAGE__->meta->make_immutable;
1;
