package EPPlication::Web::Controller::Test;
use Moose;
use namespace::autoclean;
use EPPlication::Util;
use DateTime;

BEGIN {
    extends 'CatalystX::Resource::Controller::Resource';
    with 'CatalystX::Resource::TraitFor::Controller::Resource::Delete';
}

__PACKAGE__->config(
    parent_key       => 'branch',
    parents_accessor => 'tests',
    resultset_key => 'tests',
    resource_key  => 'test',
    form_class    => 'EPPlication::Web::Form::Test',
    model         => 'DB::Test',
    redirect_mode => 'show',
    traits        => [qw/ List Create Show Edit Form /],
    actions       => {
        base => {
            Chained  => '/branch/base_with_id',
            PathPart => 'test',
        },
    },
);

before 'base' => sub {
    my ( $self, $c ) = @_;
    my $branch_id = $c->session->{active_branch}{id};
    my $branch = $c->model('DB::Branch')->find($branch_id);
    # override tests
    $c->stash->{tests} = $branch->tests;
};

before 'delete' => sub {
    my ( $self, $c ) = @_;
    my $test = $c->stash->{test};
    if ( $test->parent_tests->count ) {
        $c->flash->{error_msg} =
          'The test you attempted to delete is still in use in another test.';
        $c->res->redirect( $c->req->referer // '/' );
        $c->detach;
    }
};

sub details : Chained('/test/base_with_id') PathPart('details') Args(0){
    my ($self, $c) = @_;

    my $test = $c->stash->{test};
    my $test_name = $test->name;
    my $data = $test->list_variables_as_str;
    $data = length $data ? $data : 'No details available!';

    my $modal_content = <<"HERE";
<div class="modal-header">
  <button data-dismiss="modal" class="close">&times;</button>
  <h3>$test_name</h3>
</div>
<div class="modal-body">
  <pre>$data</pre>
</div>
HERE
    $c->res->body( $modal_content );
}

sub select_config : Chained('/test/base_with_id') PathPart('select_config') Args(0) {
    my ( $self, $c ) = @_;
    $c->session->{active_config}{id}   = $c->stash->{test}->id;
    $c->session->{active_config}{name} = $c->stash->{test}->name;
    $c->res->redirect( $c->req->referer // '/' );
}
sub clear_config : Chained('/login/required') PathPart('clear_config') Args(0) {
    my ($self, $c) = @_;
    delete $c->session->{active_config};
    $c->res->redirect( $c->req->referer // '/' );
}

__PACKAGE__->meta->make_immutable;
1;
