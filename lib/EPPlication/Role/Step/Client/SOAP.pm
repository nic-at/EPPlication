package EPPlication::Role::Step::Client::SOAP;
use Moose::Role;

has 'soap_client' => (
    is        => 'ro',
    isa       => 'EPPlication::Client::SOAP',
    required  => 1,
);

1;
