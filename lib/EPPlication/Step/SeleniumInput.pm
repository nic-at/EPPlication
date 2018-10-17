package EPPlication::Step::SeleniumInput;

use Moose;
use EPPlication::Role::Step::Parameters;
with
  'EPPlication::Role::Step::Base',
  'EPPlication::Role::Step::Client::Selenium',
  Parameters(parameter_list => [qw/ identifier locator selector input /]),
  ;

sub process {
    my ($self) = @_;

    my $identifier = $self->identifier;
    my $locator    = $self->locator;
    my $selector   = $self->selector;
    my $input      = $self->input;

    $self->add_detail("Driver identifier: $identifier");
    $self->add_detail('Locator; ' . $locator);
    $self->add_detail('Selector: ' . $selector);
    $self->add_detail('Input: ' . $input);

    die "driver doesn't exist"
      if !$self->selenium_client->driver_exists($identifier);

    my $driver = $self->selenium_client->get_driver($identifier);
    my $locator_sub = 'find_element_by_' . $locator;
    my $el = $driver->$locator_sub($selector);
    $el->send_keys($input);

    return $self->result;
}

__PACKAGE__->meta->make_immutable;
1;
