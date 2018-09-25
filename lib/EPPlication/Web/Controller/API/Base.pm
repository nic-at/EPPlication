package EPPlication::Web::Controller::API::Base;

use Moose;
use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller::REST' }

# temporary bugfix
# http://stackoverflow.com/questions/31983228/how-come-with-catalystcontrollerrest-i-get-an-error-about-content-type
# https://rt.cpan.org/Public/Bug/Display.html?id=106403
# Once bug is fixed remove this line and go through all API controllers
# and replace "entity => []" with "entity => undef"
__PACKAGE__->config(default => 'application/json');

__PACKAGE__->meta->make_immutable;
1;
