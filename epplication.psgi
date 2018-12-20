use strict;
use warnings;

use FindBin qw($Bin);
use lib "$Bin/lib";
use EPPlication::Web;

my $app = EPPlication::Web->apply_default_middlewares(EPPlication::Web->psgi_app);
$app;
