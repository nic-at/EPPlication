package EPPlication::Role::Step::Client::Selenium;
use Moose::Role;

has 'selenium_client' => (
    is       => 'ro',
    isa      => 'EPPlication::Client::Selenium',
    required => 1,
);

1;
