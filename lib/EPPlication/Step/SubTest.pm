package EPPlication::Step::SubTest;
use Moose;
with 'EPPlication::Role::Step::SubTest' ;

sub process {
    my ($self) = @_;

    my $subtest = $self->get_subtest();

    $self->add_detail('SubTest: ' . $subtest->name);
    $self->add_detail($subtest->steps->active->count . ' step(s)');

    $self->add_subtest_steps(
        map {
            { $_->get_inflated_columns }
        } $subtest->steps_rs->active->default_order->all
    );

    return $self->result;
}

__PACKAGE__->meta->make_immutable;
1;
