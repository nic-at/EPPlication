package EPPlication::Role::Step::Client::DB;
use Moose::Role;

has 'db_client' => (
    is        => 'ro',
    isa       => 'EPPlication::Client::DB',
    required  => 1,
);

1;
