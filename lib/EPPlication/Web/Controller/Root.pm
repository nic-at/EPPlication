package EPPlication::Web::Controller::Root;
use Moose;
use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller' }
with 'Catalyst::ControllerRole::CatchErrors';
__PACKAGE__->config(namespace => '');

sub auto : Private {
    my ( $self, $c ) = @_;

    if ( $c->user_exists ) {
        $c->stash( branchoptions => [ $c->model('DB::Branch')->default_order->all ] );

        my $branch;
        if ( !exists $c->session->{active_branch} ) {
            $branch = $c->model('DB::Branch')->find( { name => 'master' } );
            $c->session(
                active_branch => {
                    id   => $branch->id,
                    name => $branch->name
                }
            );
        }

        $branch = $c->model('DB::Branch')->find($c->session->{active_branch}{id});
        $c->stash( configs => [ $branch->tests->with_config_tag->default_order->all ] );

        # highlight active navbar link
        my @path_parts = split( '/', $c->req->path );
        if ( ( scalar @path_parts > 0 ) && ( $path_parts[0] ne 'api' ) ) {
            my $active = $path_parts[0];
            # /branch/1/test => 'test'
            $active = $path_parts[2] if ($active eq 'branch' && scalar @path_parts > 2);
            $c->stash( active => $active );
        }
    }
    1;
}

sub index : Path Args(0) {}

sub default : Path {
    my ( $self, $c ) = @_;
    my $error_msg =
      exists $c->stash->{error_msg}
      ? $c->stash->{error_msg}
      : 'Page not found';

    $c->stash(
        error_msg => $error_msg,
        template  => 'index.tt',
    );
    $c->response->status(404);
}

sub forbidden : Private {
    my ($self, $c) = @_;
    $c->stash(
        error_msg => 'Forbidden',
        template  => 'index.tt',
    );
    $c->response->status(403);
}

sub catch_errors : Private {
    my ( $self, $c, @errors ) = @_;

    my $error = join( "\n", @errors );
    $c->response->status(500);
    $c->log->debug( "Internal Error: " . $error ) if $c->debug;
    $c->stash(
        error_msg => $error,
        template  => 'index.tt',
    );
}

sub help : Chained('/login/required') PathPart('help') Args(0) {}

sub end : ActionClass('RenderView') {}

__PACKAGE__->meta->make_immutable;
1;
