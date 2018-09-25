package EPPlication::Role::Step::Client::REST;
use Moose::Role;

has 'rest_client' => (
    is       => 'ro',
    isa      => 'EPPlication::Client::REST',
    required => 1,
);

1;
