package EPPlication::Role::Step::SSHKeyPaths;
use Moose::Role;
use MooseX::Types::Path::Class;

has [qw/ssh_public_key_path ssh_private_key_path/] => (
    is       => 'rw',
    isa      => 'Path::Class::File',
    required => 1,
    coerce   => 1,
);

1;
