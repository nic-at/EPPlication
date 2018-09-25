package EPPlication::Role::Step::SubTest;
use Moose::Role;
use EPPlication::Role::Step::Parameters;

with
  'EPPlication::Role::Step::Base',
  Parameters( parameter_list => [qw/ subtest_id /] ),
  ;

has 'tests' => (
    is       => 'ro',
    isa      => 'EPPlication::Schema::ResultSet::Test',
    required => 1,
);

has 'subtest_steps' => (
    is       => 'rw',
    isa      => 'ArrayRef[HashRef]',
    traits   => ['Array'],
    lazy     => 1,
    default  => sub { [] },
    handles  => { add_subtest_steps => 'push' },
    init_arg => undef,
);

sub get_subtest {
    my ($self) = @_;

    my $subtest_id = $self->subtest_id;
    my $subtest    = $self->tests->find($subtest_id);
    die "SubTest does not exist. ($subtest_id)\n"
      unless $subtest;

    return $subtest;
}

1;
