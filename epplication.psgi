use strict;
use warnings;
use EPPlication::Web;

my $app = EPPlication::Web->apply_default_middlewares(EPPlication::Web->psgi_app);
$app;
