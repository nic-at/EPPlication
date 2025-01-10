package EPPlication::Web::Controller::API::Test;

use Moose;
use namespace::autoclean;
use List::Util qw/ any /;
use Try::Tiny;
use Parqus;
BEGIN { extends 'EPPlication::Web::Controller::API::Base' }

sub _apply_search_query {
    my ($c, $test_rs) = @_;

    my $query_str = $c->req->query_params->{search};
    return $test_rs unless defined $query_str;
    return $test_rs unless length($query_str) > 0;
    my $parser = Parqus->new( keywords => [qw/ comment name /] );
    my $res = $parser->process($query_str);
    $c->detach( $c->controller('API::Root')->action_for('error'), [join( "\n", @{ $res->{errors} } )] )
      if exists $res->{errors};

    if ( exists $res->{keywords} ) {
        my %query = %{ $res->{keywords} };

        if ( $query{name} ) {
            $test_rs = $test_rs->search_name($_) for @{ $query{name} };
        }
        if ( $query{comment} ) {
            $test_rs = $test_rs->search_comment($_) for @{ $query{comment} };
        }
    }
    return $test_rs
}

sub _get_active_tags {
    my ($c) = @_;

    my $active_tags = $c->req->query_params->{tags};
    if (defined $active_tags) {
        $active_tags = [$active_tags] unless ref $active_tags;
    }
    else {
        $active_tags = [];
    }

    my $show_all      = 0;
    my $show_untagged = 0;

    my $i = 0;
    for my $tag (@$active_tags) {
        if ($tag eq 'all') {
            $show_all = 1;
            splice(@$active_tags, $i, 1);
            last;
        }
        $i++;
    }
    $i = 0;
    for my $tag (@$active_tags) {
        if ($tag eq 'untagged') {
            $show_untagged = 1;
            splice(@$active_tags, $i, 1);
            last;
        }
        $i++;
    }

    return ($active_tags, $show_all, $show_untagged);
}

sub _get_tags {
    my ( $c, $active_tags ) = @_;

    my @tags = map { { id => $_->id, name => $_->name } }
      $c->model('DB::Tag')->search( {}, { columns => [qw/id name/] } )->all;

    for my $tag (@tags) {
        $tag->{active} = any { $tag->{id} == $_ } @$active_tags;
    }

    @tags = sort { lc( $a->{name} ) cmp lc( $b->{name} ) } @tags;

    return \@tags;
}

sub _apply_tag_filter {
    my ( $c, $test_rs ) = @_;

    my ($active_tags, $show_all, $show_untagged) = _get_active_tags($c);

    my $tags = _get_tags( $c, $active_tags );

    # all tests pass through the tagfilter, tag selection is ignored.
    return $test_rs if $show_all;

    # only untagged tests pass through the tagfilter, tag selection is ignored.
    return $test_rs->filter_untagged->search_rs if $show_untagged;

    # if no tag is active return empty result
    return $test_rs->search_rs( \'0 = 1' ) if scalar @$active_tags == 0;

    # filter tests according to tag selection
    return $test_rs->filtered_by_tag_ids($active_tags)->search_rs;
}

sub base : Chained('/api/base_with_auth') PathPart('test') CaptureArgs(0) {}

sub index : Chained('base') PathPart('') ActionClass('REST') Args(0) {}
sub index_GET {
    my ( $self, $c) = @_;

    my $branch = exists $c->req->params->{branch_id}
        ? $c->model('DB::Branch')->find($c->req->params->{branch_id})
        : $c->model('DB::Branch')->find('master', {key=>'branch_name'});

    $c->detach( $c->controller('API::Root')->action_for('error'), ["Couldn't find branch."] )
        unless $branch;

    my $test_rs = $branch->tests_rs;
    $test_rs = _apply_tag_filter($c, $test_rs);
    $test_rs = _apply_search_query($c, $test_rs);
    my @tests = $test_rs->with_tags->default_order->all;
    my @tests_data = ();
    for my $test (@tests) {
        my %test_data = $test->get_columns;
        $test_data{tags} = [];
        for my $tag ( $test->tags->default_order->all ) {
            my %tag_data = $tag->get_columns;
            push(@{ $test_data{tags} }, \%tag_data);
        }
        push(@tests_data, \%test_data);
    }
    $self->status_ok(
        $c,
        entity => \@tests_data,
    );
}
sub item : Chained('base') PathPart('') ActionClass('REST') Args(1) {}
sub item_DELETE {
    my ( $self, $c, $test_id ) = @_;
    my $test = $c->model('DB::Test')->find($test_id);

    if ( $test->parent_tests->count ) {
        $c->detach(
            $c->controller('API::Root')->action_for('error'),
            ['Cannot delete ' . $test->name . ' because other tests use it.']
        );
    }
    else {
        $test->delete;
        $self->status_ok(
            $c,
            entity => {},
        );
    }
}
sub item_PUT {
    my ( $self, $c, $test_id ) = @_;
    my $test = $c->model('DB::Test')->find($test_id);
    my $new_test_name = $c->req->data->{test_name};
    $test->update({ name => $new_test_name });
    $self->status_ok(
        $c,
        entity => {},
    );
}
sub clone : Chained('base') PathPart('clone') ActionClass('REST') Args(0) {}
sub clone_POST {
    my ($self, $c) = @_;
    my $test_id  = $c->req->body_params->{test_id};
    my $test     = $c->model('DB::Test')->find($test_id);
    my $clone    = $test->clone({ name => $test->name . ' (CLONE)', });
    my $location = $c->uri_for($c->controller('Test')->action_for('edit'), [ $clone->branch_id, $clone->id ]);
    $c->flash->{msg} = $test->name . ' cloned successfully.';
    $self->status_created(
        $c,
        location => $location->as_string,
        entity => {},
    );
}

sub lookup : Chained('base') PathPart('lookup') ActionClass('REST') Args(0) {}
sub lookup_GET {
    my ( $self, $c ) = @_;

    try {
        die "Can't lookup test without test name."
          unless exists $c->req->params->{name};
        my $test_name = $c->req->params->{name};

        my $branch = exists $c->req->params->{branch_id}
            ? $c->model('DB::Branch')->find($c->req->params->{branch_id})
            : $c->model('DB::Branch')->find('master', {key=>'branch_name'});
        my $test = $branch->tests->find( $branch->id, $test_name, { key => 'test_branch_id_name' } );

        if ($test) {
            $self->status_ok(
                $c,
                entity => {
                    test_id => $test->id,
                },
            );
        }
        else {
            $self->status_not_found(
                $c,
                message => 'test not found.',
            );
        }
    }
    catch {
        my $error = $_;
        $c->detach( $c->controller('API::Root')->action_for('error'), [$error] );
    };
}

__PACKAGE__->meta->make_immutable;
1;
