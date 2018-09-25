package EPPlication::Util::Config;

use strict;
use warnings;
use Config::ZOMG;
use Dir::Self;
use Memoize;

memoize('get');

sub get {
    my $home = __DIR__ . '/../../..';
    my $zomg = Config::ZOMG->new(
        name       => "EPPlication::Web",
        path       => $home,
        env_lookup => 'CATALYST',
    );
    my $config = $zomg->load;
    return $config;
}

1;
