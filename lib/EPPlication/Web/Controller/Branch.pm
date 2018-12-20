package EPPlication::Web::Controller::Branch;
use Moose;
use namespace::autoclean;

BEGIN {
    extends 'CatalystX::Resource::Controller::Resource';
    with 'CatalystX::Resource::TraitFor::Controller::Resource::List';
    with 'CatalystX::Resource::TraitFor::Controller::Resource::Form';
    with 'CatalystX::Resource::TraitFor::Controller::Resource::Edit';
    with 'CatalystX::Resource::TraitFor::Controller::Resource::Delete';
}

__PACKAGE__->config(
    resultset_key => 'branches',
    resource_key  => 'branch',
    form_class    => 'EPPlication::Web::Form::Branch',
    model         => 'DB::Branch',
    redirect_mode => 'list',
    traits        => [qw/ -Show /],
    actions       => {
        base => {
            Chained  => '/login/required',
            PathPart => 'branch',
        },
    },
);

before 'list' => sub {
    my ( $self, $c ) = @_;
    if (!$c->check_user_roles('can_list_branches')) {
        $c->detach( $c->controller('Root')->action_for('forbidden') );
    }
};

before 'edit'  => sub {
    my ( $self, $c ) = @_;
    if (!$c->check_user_roles('can_edit_branches')) {
        $c->detach( $c->controller('Root')->action_for('forbidden') );
    }
};

before 'delete' => sub {
    my ( $self, $c ) = @_;
    if (!$c->check_user_roles('can_delete_branches')) {
        $c->detach( $c->controller('Root')->action_for('forbidden') );
    }
    my $branch        = $c->stash->{ $self->resource_key };
    my $active_branch = $c->session->{active_branch};
    if ($branch->id == $active_branch->{id}) {
      die "You cannot delete the currently active branch.\n";
    }
};

sub select: Chained('/branch/base_with_id') PathPart('select') Args(0) {
    my ( $self, $c ) = @_;
    my $branch = $c->stash->{branch};
    $c->session(
        active_branch => {
            id   => $branch->id,
            name => $branch->name
        }
    );
    $c->flash->{msg} = "Switched to branch: ".$branch->name;
    $c->res->redirect(
        $c->uri_for($c->controller('Test')->action_for('list'), [ $branch->id ])
    );
}

__PACKAGE__->meta->make_immutable;
1;
