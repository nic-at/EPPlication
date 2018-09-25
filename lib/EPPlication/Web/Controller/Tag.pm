package EPPlication::Web::Controller::Tag;
use Moose;
use namespace::autoclean;

BEGIN {
    extends 'CatalystX::Resource::Controller::Resource';
    with 'CatalystX::Resource::TraitFor::Controller::Resource::List';
    with 'CatalystX::Resource::TraitFor::Controller::Resource::Form';
    with 'CatalystX::Resource::TraitFor::Controller::Resource::Create';
    with 'CatalystX::Resource::TraitFor::Controller::Resource::Edit';
    with 'CatalystX::Resource::TraitFor::Controller::Resource::Delete';
}

__PACKAGE__->config(
    resultset_key => 'tags',
    resource_key  => 'tag',
    form_class    => 'EPPlication::Web::Form::Tag',
    model         => 'DB::Tag',
    redirect_mode => 'list',
    traits        => [ qw/ -Show /],
    actions       => {
        base => {
            Chained  => '/login/required',
            PathPart => 'tag',
        },
    },
);

before 'list' => sub {
    my ( $self, $c ) = @_;
    if (!$c->check_user_roles('can_list_tags')) {
        $c->detach( $c->controller('Root')->action_for('forbidden') );
    }
};

before 'create' => sub {
    my ( $self, $c ) = @_;
    if (!$c->check_user_roles('can_create_tags')) {
        $c->detach( $c->controller('Root')->action_for('forbidden') );
    }
};

before 'edit'  => sub {
    my ( $self, $c ) = @_;
    if (!$c->check_user_roles('can_edit_tags')) {
        $c->detach( $c->controller('Root')->action_for('forbidden') );
    }
};

before 'delete' => sub {
    my ( $self, $c ) = @_;
    if (!$c->check_user_roles('can_delete_tags')) {
        $c->detach( $c->controller('Root')->action_for('forbidden') );
    }
};

__PACKAGE__->meta->make_immutable;
1;
