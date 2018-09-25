package EPPlication::Web::Controller::API::Tag;

use Moose;
use List::Util qw/none/;
use namespace::autoclean;
BEGIN { extends 'EPPlication::Web::Controller::API::Base' }

sub base : Chained('/api/base_with_auth') PathPart('tag') CaptureArgs(0) {}

sub _get_all_tags {
    my ( $self, $c ) = @_;
    my @tags = $c->model('DB::Tag')->default_order->all;
    my @tags_data = ();
    for my $tag (@tags) {
        my %tag_data = $tag->get_columns;
        push(@tags_data, \%tag_data);
    }
    return @tags_data;
}

sub index : Chained('base') PathPart('') ActionClass('REST') Args(0) {}
sub index_GET {
    my ( $self, $c ) = @_;
    my @tags_data = $self->_get_all_tags($c);
    $self->status_ok(
        $c,
        entity => \@tags_data,
    );
}

sub tag_test : Chained('base') PathPart('tag_test') ActionClass('REST') Args(0) {}
sub tag_test_GET {
    my ( $self, $c ) = @_;
    my $test_id   = $c->req->param('test_id');
    my $test      = $c->model('DB::Test')->find($test_id);
    my $tags_rs   = $test->tags->default_order;
    my @tags      = $tags_rs->all;
    my @tags_data = ();
    for my $tag (@tags) {
        my %tag_data = $tag->get_columns;
        push(@tags_data, \%tag_data);
    }
    my @all_tags_data = $self->_get_all_tags($c);
    my @available_tags_data = ();
    for my $t (@all_tags_data) {
        if ( none{ $t->{id} == $_->{id} } @tags_data ) {
            push(@available_tags_data, $t);
        }
    }
    $self->status_ok(
        $c,
        entity => {
            tags => \@tags_data,
            available_tags => \@available_tags_data,
        },
    );
}
sub tag_test_POST {
    my ( $self, $c ) = @_;

    my $data    = $c->req->data;
    my $test_id = $data->{test_id};
    my $tag_id  = $data->{tag_id};
    my $tag  = $c->model('DB::Tag')->find($tag_id);
    my $test = $c->model('DB::Test')->find($test_id);
    $test->add_to_tags($tag);
    $self->status_ok(
        $c,
        entity => {},
    );
}
sub tag_test_DELETE {
    my ( $self, $c ) = @_;

    my $data    = $c->req->data;
    my $test_id = $data->{test_id};
    my $tag_id  = $data->{tag_id};
    my $test = $c->model('DB::Test')->find($test_id);
    my $tag  = $c->model('DB::Tag')->find($tag_id);
    $test->remove_from_tags($tag);
    $self->status_ok(
        $c,
        entity => {},
    );
}

__PACKAGE__->meta->make_immutable;
1;
