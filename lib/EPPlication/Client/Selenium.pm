package EPPlication::Client::Selenium;
use Moose;
use namespace::autoclean;
use Selenium::Firefox;

has 'drivers' => (
    traits    => ['Hash'],
    is        => 'rw',
    isa       => 'HashRef[Selenium::Firefox]',
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
