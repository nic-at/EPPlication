package EPPlication::Role::Step::Client::HTTP;
use Moose::Role;

has 'http_client' => (
    is       => 'ro',
    isa      => 'EPPlication::Client::HTTP',
    required => 1,
);

1;
