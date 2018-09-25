package EPPlication::Role::Step::Util::ProcessTemplate;
use Moose::Role;

requires 'stash';

has 'tt' => (
    is        => 'ro',
    isa       => 'Template',
    required  => 1,
);

sub process_template {
    my ( $self, $tt_in ) = @_;
    my $tt_out = q{};
    my $stash  = $self->get_stash_for_tt;
    $self->tt->process( \$tt_in, $stash, \$tt_out )
      or die q{} . $self->tt->error() . "\n";
    return $tt_out;
}

1;
