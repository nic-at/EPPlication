package EPPlication::Web::Controller::User;
use Moose;
use namespace::autoclean;

__PACKAGE__->config(
    resultset_key          => 'users',
    resource_key           => 'user',
    form_class             => 'EPPlication::Web::Form::User',
    model                  => 'DB::User',
    redirect_mode          => 'list',
    traits                 => [qw/ -Show /],
    activate_fields_create => [qw/ password password_repeat /],
    activate_fields_edit   => [qw/ edit_with_password /],
    actions                => {
        base => {
            Chained  => '/login/required',
            PathPart => 'user',
        },
    },
);

BEGIN {
    extends 'CatalystX::Resource::Controller::Resource';
    with 'CatalystX::Resource::TraitFor::Controller::Resource::List';
    with 'CatalystX::Resource::TraitFor::Controller::Resource::Form';
    with 'CatalystX::Resource::TraitFor::Controller::Resource::Edit';
    with 'CatalystX::Resource::TraitFor::Controller::Resource::Create';
    with 'CatalystX::Resource::TraitFor::Controller::Resource::Delete';
}

sub edit_with_password : Method('GET') Method('POST') Chained('base_with_id')
    PathPart('edit_with_password') Args(0) {
    my ( $self, $c ) = @_;
    $c->stash(activate_form_fields => [qw/ password password_repeat /]);
    $c->forward($self->action_for('edit'));
}

before 'list' => sub {
    my ( $self, $c ) = @_;
    if (!$c->check_user_roles('can_list_users')) {
        $c->detach( $c->controller('Root')->action_for('forbidden') );
    }
};

before 'create' => sub {
    my ( $self, $c ) = @_;
    if (!$c->check_user_roles('can_create_users')) {
        $c->detach( $c->controller('Root')->action_for('forbidden') );
    }
};

before ['edit', 'edit_with_password']  => sub {
    my ( $self, $c ) = @_;
    if (!$c->check_user_roles('can_edit_users')) {
        $c->detach( $c->controller('Root')->action_for('forbidden') );
    }
};

before 'delete' => sub {
    my ( $self, $c ) = @_;
    if (!$c->check_user_roles('can_delete_users')) {
        $c->detach( $c->controller('Root')->action_for('forbidden') );
    }
};

__PACKAGE__->meta->make_immutable;
1;
