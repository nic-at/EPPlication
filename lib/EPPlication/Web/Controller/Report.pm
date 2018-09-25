package EPPlication::Web::Controller::Report;
use Moose;
use MooseX::Types::Path::Class;
use Path::Class qw//;
use namespace::autoclean;
use IO::File::WithPath;

BEGIN { extends 'Catalyst::Controller' }

has 'root' => (
    is       => 'ro',
    isa      => 'Path::Class::Dir',
    required => 1,
    coerce   => 1,
    init_arg => undef,
    default  => sub {
        my $self = shift;
        my $config = $self->_app->config;
        return $config->{'Model::DB'}{job_export_dir};
    },
);

sub base : Chained('/login/required') CaptureArgs(0) PathPart('report') {}
sub list : Chained('base') PathPart('list') Args {
    my ( $self, $c, @args ) = @_;
    my $dir = Path::Class::dir( $self->root, @args );
    $self->_restrict_path($dir);
    my @paths = sort { $b->absolute cmp $a->absolute } $dir->children( no_hidden => 1 );
    my $paths_ref = $self->process_paths( $c, \@paths );
    $c->stash( reports => $paths_ref );
}

sub process_paths {
    my ( $self, $c, $paths ) = @_;
    my @new_paths = ();
    for my $path (@$paths) {
        my $rel = $path->relative($self->root);
        my $url;
        if($path->is_dir) {
            $url = $c->uri_for( $self->action_for('list'), $rel->components ),
        }
        else {
            next unless $path->stringify =~ m/\.bz2$/xms;
            $url = $c->uri_for( $self->action_for('file'), $rel->components ),
        }
        push( @new_paths, { name => $rel, url => $url } );
    }
    return \@new_paths;
}

sub _restrict_path {
    my ($self, $path) = @_;
    die "Cannot access paths outside job_export_dir. ($path)"
        unless $self->root->contains($path);
}

sub file : Chained('base') PathPart('file') Args {
    my ( $self, $c, @args ) = @_;
    my $file = $self->root->file(@args);
    die 'Not a ".bz2" file extension'
        unless $file->stringify =~ m/\.bz2$/xms;;
    $self->_restrict_path($file);
    my $fh = IO::File::WithPath->new($file->stringify);
    $c->response->body($fh);
    $c->response->content_type('application/x-bzip2');
}

__PACKAGE__->meta->make_immutable;
1;
