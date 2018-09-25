package EPPlication::Role::Step::Client::Whois;
use Moose::Role;

has 'whois_client' => (
    is       => 'ro',
    isa      => 'EPPlication::Client::Whois',
    required => 1,
);

1;
