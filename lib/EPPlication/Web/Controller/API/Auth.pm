package EPPlication::Web::Controller::API::Auth;
use Moose;
use namespace::autoclean;
use Try::Tiny;
BEGIN { extends 'EPPlication::Web::Controller::API::Base' }

sub login : Chained('/api/base') PathPart('login') Args(0) ActionClass('REST') {}
sub login_POST {
    my ( $self, $c ) = @_;
    if ( $c->authenticate( $c->req->data ) ) {
        $self->status_ok(
            $c,
            entity => { message => 'login successful.' },
        );
    }
    else {
        $self->status_bad_request(
            $c,
            message => 'Authentication failed.',
        );
    }
}

sub logout : Chained('/api/base_with_auth') PathPart('logout') Args(0) ActionClass('REST') {}
sub logout_POST {
    my ( $self, $c ) = @_;
    $c->logout;
    $self->status_ok(
        $c,
        entity => { message => 'logout successful.' },
    );
}

__PACKAGE__->meta->make_immutable;
1;
