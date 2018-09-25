package EPPlication::Web::Controller::API::Branch;

use Moose;
use namespace::autoclean;
use Try::Tiny;
BEGIN { extends 'EPPlication::Web::Controller::API::Base' }

sub base : Chained('/api/base_with_auth') PathPart('branch') CaptureArgs(0) {}

sub lookup : Chained('base') PathPart('lookup') ActionClass('REST') Args(0) {}
sub lookup_GET {
    my ( $self, $c ) = @_;

    try {
        die "Can't lookup branch without branch name."
          unless exists $c->req->params->{name};

        my $branch_name = $c->req->params->{name};

        my $branch = $c->model('DB::Branch')->find( $branch_name, { key => 'branch_name' } );
        if ($branch) {
            $self->status_ok(
                $c,
                entity => {
                    branch_id => $branch->id,
                },
            );
        }
        else {
            $self->status_not_found(
                $c,
                message => 'branch not found.',
            );
        }
    }
    catch {
        my $error = $_;
        $c->detach( $c->controller('API::Root')->action_for('error'), [$error] );
    };
}

__PACKAGE__->meta->make_immutable;
1;
