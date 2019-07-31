use strict;
use warnings;

use Dir::Self;
use lib __DIR__ . "/lib";
use EPPlication::Web;

my $app = EPPlication::Web->psgi_app;
$app;
