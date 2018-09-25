package EPPlication::Web::Controller::API::Root;

use Moose;
use Try::Tiny;
use namespace::autoclean;
BEGIN { extends 'EPPlication::Web::Controller::API::Base' }
__PACKAGE__->config( namespace => 'api' );
with 'Catalyst::ControllerRole::CatchErrors';

sub base : Chained('/') PathPart('api') CaptureArgs(0) {}
sub base_with_auth : Chained('base') PathPart('') CaptureArgs(0) {
    my ( $self, $c ) = @_;
    if ( !$c->user_exists ) {
        $self->status_forbidden(
            $c,
            message => 'access denied, authentication needed.',
        );
        $c->detach;
    }
}

sub default : Path {
    my ( $self, $c ) = @_;
    $self->status_not_found( $c, message => "unknown request path." );
}

sub version : Chained('base_with_auth') PathPart('version') Args(0)  ActionClass('REST') { }
sub version_GET {
    my ( $self, $c ) = @_;
    try {
        $self->status_ok(
            $c,
            entity => {
                EPPlication => $c->VERSION,
                database    => $c->model('DB')->schema->VERSION,
            },
        );
    }
    catch {
        my $error = $_;
        $c->detach( $self->action_for('error'), [$error] );
    };
}

sub error : Private {
    my ( $self, $c, $message ) = @_;
    $message = defined $message ? $message : 'Unknown Error.';
    $self->status_bad_request(
        $c,
        message => $message,
    );
}

# FIXME: Catalyst::ControllerRole::CatchErrors [1] doesnt work with Catalyst::Action::REST [2]
# because [1] has a 'before end' modifier and [2] comes with its own end method.
#sub end : Private { }
sub catch_errors : Private {
    my ( $self, $c, @errors ) = @_;
    my $error = join( "\n", @errors );
    $c->response->status(500);
    $c->log->debug( "Internal Error: " . $error ) if $c->debug;
    $c->detach( $self->action_for('error'), [$error] );
}

__PACKAGE__->meta->make_immutable;
1;
