package EPPlication::Web::Controller::API::Step;

use Moose;
use namespace::autoclean;
use Try::Tiny;
BEGIN { extends 'EPPlication::Web::Controller::API::Base' }

sub base : Chained('/api/base_with_auth') PathPart('step') CaptureArgs(0) {}

sub index : Chained('base') PathPart('') ActionClass('REST') Args(0) {
    my ( $self, $c ) = @_;
    my $test_id  = $c->req->param('test_id');
    my $test     = $c->model('DB::Test')->find($test_id);
    $c->stash(test => $test);
}
sub index_GET {
    my ( $self, $c ) = @_;
    my $test = $c->stash->{test};
    my $steps_rs = $test->steps->default_order;
    my @steps = $steps_rs->all;
    my @steps_data = ();
    for my $step (@steps) {
        # add subtest_name to json data
        if ($step->has_subtest) {
            $step->parameters(
                {
                    %{ $step->parameters },
                    subtest_name => $step->subtest->name,
                }
            );
        }
        my %step_data = $step->get_columns;
        push(@steps_data, \%step_data);
    }
    $self->status_ok(
        $c,
        entity => { steps => \@steps_data },
    );
}
sub index_PUT {
    my ( $self, $c ) = @_;
    my $test      = $c->stash->{test};
    my $data      = $c->req->data;
    my $step_data = $data->{step_data};
    my $index     = $data->{index};
    delete $step_data->{id};
    delete $step_data->{test_id};
    my $steps_rs = $test->steps_rs;
    my $step     = $steps_rs->create($step_data);
    _move_to_index($test, $step, $index);
    $self->status_ok(
        $c,
        entity => {
            $step->get_columns,
        },
    );
}
sub index_DELETE {
    my ( $self, $c ) = @_;
    my $test      = $c->stash->{test};
    my $step_id   = $c->req->param('step_id');
    my $step      = $test->steps->find($step_id);
    $step->delete;
    $self->status_ok(
        $c,
        entity => [],
    );
}
sub index_POST {
    my ( $self, $c ) = @_;
    my $test      = $c->stash->{test};
    my $step_id   = $c->req->param('step_id');
    my $step      = $test->steps->find($step_id);
    my $index     = $c->req->param('index');
    _move_to_index($test, $step, $index);
    $self->status_ok(
        $c,
        entity => [],
    );
}

# frontend always maintains gapless ordering (e.g.: 1,2,3,4,5)
# DBIC::Ordered might have gaps (e.g.: 1,2,4,5,6)
# so we look up the item at index provided from frontend
# and move $step to that items position.
sub _move_to_index {
    my ($test, $step, $index) = @_;
    my $target_step = $test->steps->default_order->search( {}, { offset => $index, rows => 1 } )->single;
    $step->move_to($target_step->position);
}

__PACKAGE__->meta->make_immutable;
1;
