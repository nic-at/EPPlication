package EPPlication::Client::Selenium;
use Moose;
use namespace::autoclean;
use Selenium::Remote::Driver;

has 'drivers' => (
    traits    => ['Hash'],
    is        => 'rw',
    isa       => 'HashRef[Selenium::Remote::Driver]',
    default   => sub { {} },
    handles   => {
        driver_exists => 'exists',
        get_driver    => 'get',
        set_driver    => 'set',
        delete_driver => 'delete',
    },
);

__PACKAGE__->meta->make_immutable;
1;
