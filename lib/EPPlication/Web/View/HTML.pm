package EPPlication::Web::View::HTML;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    render_die         => 1,
    expose_methods     => [qw/ assets /],
);

# Plack::Middleware::Assets fills $c->req->env->{'psgix.assets'}
# with js/css file paths. assets() exposes these paths to the template.
sub assets {
    my ( $self, $c ) = @_;
    my %assets = ( js => [], css => [] );
    for my $asset (@{ $c->req->env->{'psgix.assets'} }) {
        if ($asset =~ qr/\.js$/xms) {
            push(@{$assets{js}}, $asset);
        }
        elsif ($asset =~ qr/\.css$/xms) {
            push(@{$assets{css}}, $asset);
        }
    }
    return \%assets;
}

1;
