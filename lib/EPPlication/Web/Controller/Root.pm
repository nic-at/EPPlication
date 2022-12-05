package EPPlication::Web::Controller::Root;
use Moose;
use namespace::autoclean;
use List::Util qw/first/;

BEGIN { extends 'Catalyst::Controller' }
with 'Catalyst::ControllerRole::CatchErrors';
__PACKAGE__->config(namespace => '');

sub _get_active_branch {
    my ( $self, $c, $branches ) = @_;
    my $branch;
    if ( exists $c->session->{active_branch} ) {
        $branch = $c->model('DB::Branch')->find($c->session->{active_branch}{id});
        if (!$branch) {
            delete $c->session->{active_branch};
            die('Branch not found: '
                .$c->session->{active_branch}{name}.':'
                .$c->session->{active_branch}{id});
        }
    }

    if ( !$branch ) {
        if (scalar @$branches == 0) {
            die('No branch exists!');
        }
        elsif (scalar @$branches > 1) {
            $branch = first { $_->name eq 'master' } @$branches;
            $branch = $branches->[0] unless $branch;
        }
        else {
            $branch = $branches->[0] unless $branch;
        }

        $c->stash(msg => 'No branch was selected. Automatically switched to "'.$branch->name.'".');

        $c->session(
            active_branch => {
                id   => $branch->id,
                name => $branch->name
            }
        );
    }

    return $branch
}

sub _process_url {
    my ( $self, $c ) = @_;
    my @parts = split( '/', $c->req->path );
    my $num_parts = scalar @parts;

    if ( ( $num_parts > 0 ) && ( $parts[0] ne 'api' ) ) {
        my $active_link;

        if (    $num_parts >= 3
             && $parts[0] eq 'branch'
             && $parts[2] eq 'test'
             && $parts[1] =~ m/^-?\d+\z/xms
        ) {
            my $url_branch = $parts[1];

            # check if active_branch matches branch from URL
            if ($url_branch != $c->session->{active_branch}{id}) {
                my $url_branch = $c->model('DB::Branch')->find($url_branch);
                if ($url_branch) {
                    $c->detach(
                        $self->action_for('error'),
                        ['Switch to branch "'.$url_branch->name.'" to view this page.']
                    );
                }
            }

            $active_link = 'test'; # /branch/1/test => 'test'
        }
        else {
            $active_link = $parts[0]; # /job/list => 'job'
        }

        # highlight active navbar link
        $c->stash( active => $active_link );
    }
}

sub auto : Private {
    my ( $self, $c ) = @_;

    if ( $c->user_exists ) {

        my $branches = [$c->model('DB::Branch')->default_order->all];
        $c->stash( branchoptions => $branches );

        my $branch = $self->_get_active_branch($c, $branches);
        $c->stash( configs => [ $branch->tests->with_config_tag->default_order->all ] );

        $self->_process_url($c);
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

sub error : Private {
    my ( $self, $c, $error ) = @_;
    $error = defined $error ? $error : 'Unknown Error.';
    $c->stash(
        error_msg => $error,
        template  => 'index.tt',
    );
}

sub catch_errors : Private {
    my ( $self, $c, @errors ) = @_;

    my $error = join( "\n", @errors );
    $c->response->status(500);
    $c->log->debug( "Internal Error: " . $error ) if $c->debug;
    $c->forward($self->action_for('error'), [$error]);
}

sub help : Chained('/login/required') PathPart('help') Args(0) {}

sub end : ActionClass('RenderView') {}

__PACKAGE__->meta->make_immutable;
1;
