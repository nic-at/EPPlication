package EPPlication::Role::Step::Client::EPP;
use Moose::Role;

has 'epp_client' => (
    is        => 'ro',
    isa       => 'EPPlication::Client::EPP',
    required  => 1,
);

1;
