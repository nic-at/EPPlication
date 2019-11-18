package EPPlication::Web::Controller::API::User;

use Moose;
use namespace::autoclean;
BEGIN { extends 'EPPlication::Web::Controller::API::Base' }

sub base : Chained('/api/base_with_auth') PathPart('user') CaptureArgs(0) {}

sub index : Chained('base') PathPart('') ActionClass('REST') Args(0) {}
sub index_GET {
    my ( $self, $c ) = @_;
    my @users = $c->model('DB::User')->default_order->all;
    my @users_data = ();
    for my $user (@users) {
        my %user_data = $user->get_columns;
        my %response_data = map {$_ => $user_data{$_}} qw/id name/;
        push(@users_data, \%response_data);
    }
    $self->status_ok(
        $c,
        entity => \@users_data,
    );
}

__PACKAGE__->meta->make_immutable;
1;
