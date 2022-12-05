package EPPlication::Web::Controller::API::Job;

use Moose;
use namespace::autoclean;
use Try::Tiny;
use List::Util qw/ any /;
use HTML::Entities;
BEGIN { extends 'EPPlication::Web::Controller::API::Base' }

sub base : Chained('/api/base_with_auth') PathPart('job') CaptureArgs(0) {}

sub index : Chained('base') PathPart('') ActionClass('REST') Args(0) {}
sub index_GET {
    my ( $self, $c ) = @_;
    my $filter = $c->req->query_params->{filter};

    # set logged in user as default if job_filter does not exist
    $filter = $c->user->id unless $filter;

    my $jobs = $c->model('DB::Job')->filter_temp;
    if ($filter ne 'all') {
        $jobs = $jobs->search_rs( { user_id => $filter } );
    }
    my @jobs = $jobs->default_order->all;
    my @jobs_data = ();
    for my $job (@jobs) {
        push( @jobs_data, _prepare_job_data($c, $job) );
    }
    $self->status_ok(
        $c,
        entity => \@jobs_data,
    );
}

sub _prepare_job_data {
    my ($c, $job) = @_;
    my %data = $job->get_columns;
    $data{created} = $job->created->set_time_zone('Europe/Vienna')
      ->strftime('%d.%m.%Y %H:%M:%S');
    $data{duration} =
      defined $data{duration} ? sprintf( '%.2f', $data{duration} ) : '';
    $data{num_steps} = defined $data{num_steps} ? $data{num_steps} : '';
    $data{errors}  = defined $data{errors} ? $data{errors} : '';
    $data{user}    = defined $job->user ? $job->user->name : '';
    if (defined $job->config_id) {
        $data{config} = $job->config->name;
        $data{config_url} = $c->uri_for($c->controller('Test')->action_for('show'), [ $job->config->branch_id, $job->config_id ]);
    }
    if (defined $job->test_id) {
        $data{test} = $job->test->name;
        $data{test_url} = $c->uri_for($c->controller('Test')->action_for('show'), [ $job->test->branch_id,  $job->test_id ]);
        $data{branch} = $job->test->branch->name;
    }
    $data{comment} = defined $data{comment} ? $data{comment} : '';
    $data{edit_url} = $c->uri_for($c->controller('Job')->action_for('edit'), [ $job->id ]);
    $data{show_url} = $c->uri_for($c->controller('Job')->action_for('show'), [ $job->id ]);
    return \%data;
}

sub index_POST {
    my ( $self, $c ) = @_;

    my $data      = $c->req->data;
    my $job_type  = $data->{job_type};
    my $test_id   = $data->{test_id};
    my $config_id = $data->{config_id};
    my $user_id   = $c->user->get('id');

    try {
        my $job = $c->model('DB::Job')->create(
            {
                test_id => $test_id,
                type    => $job_type,
                user_id => $user_id,
                defined $config_id ? ( config_id => $config_id ) : (),
            }
        );

        my $location;
        $location =
          $c->uri_for( $c->controller('Job')->action_for('list') )
          if $job_type eq 'test';
        $location =
          $c->uri_for( $c->controller('Job')->action_for('show'), [ $job->id ] )
          if $job_type eq 'temp';

        $self->status_created(
            $c,
            location => $location->as_string,
            entity   => { job_id => $job->id },
        );
    }
    catch {
        my $e = shift;
        $c->detach(
            $c->controller('API::Root')->action_for('error'),
            ["Couldn't create job: $e"]
        );
    };
}

sub item_base : Chained('base') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $job_id ) = @_;
    $c->detach(
        $c->controller('API::Root')->action_for('error'),
        ["Can't lookup job without job id."]
    ) unless defined $job_id;
    my $job = $c->model('DB::Job')->find($job_id);
    if (!$job) {
        $self->status_not_found(
            $c,
            message => 'job not found.',
        );
        $c->detach;
    }
    else {
        $c->stash(job => $job);
    }
}
sub item : Chained('item_base') PathPart('') ActionClass('REST') Args(0) {}
sub item_GET {
    my ( $self, $c, $job_id ) = @_;
    my $job = $c->stash->{job};
    $self->status_ok(
        $c,
        entity => {
            status  => $job->status,
            summary => $job->get_summary,
        },
    );
}
sub item_DELETE {
    my ( $self, $c, $job_id ) = @_;
    my $job = $c->stash->{job};
    $job->delete;
    $self->status_ok(
        $c,
        entity => {},
    );
}

sub item_abort : Chained('item_base') PathPart('abort') ActionClass('REST') Args(0) {}
sub item_abort_POST {
    my ( $self, $c ) = @_;
    my $job = $c->stash->{job};
    if ($job->status eq 'in_progress') {
        $job->update({ status => 'aborting' });
        $self->status_ok(
            $c,
            entity => { msg => 'aborting' },
        );
    }
    else {
        $self->status_bad_request(
            $c,
            message => 'not aborting, task status not "in_progress"',
        );
    }
}

sub export : Chained('base') PathPart('export') ActionClass('REST') Args(0) {}
sub export_POST {
    my ( $self, $c ) = @_;

    my $data = $c->req->data;
    my $job_id = $data->{job_id};

    $c->detach(
        $c->controller('API::Root')->action_for('error'),
        ["Can't lookup job without job id."]
    ) unless defined $job_id;

    try {
        my $job = $c->model('DB::Job')->find( $job_id );
        if ($job) {
            my $rel_location = $job->export;
            my $location = $c->uri_for($self->action_for('file'), $rel_location->components);
            $self->status_created(
                $c,
                location => $location->as_string,
                entity => [],
            );
        }
        else {
            $self->status_not_found(
                $c,
                message => 'job not found.',
            );
        }
    }
    catch {
        my $error = $_;
        $c->detach( $c->controller('API::Root')->action_for('error'), [$error] );
    };
}

sub file : Chained('base') PathPart('file') ActionClass('REST') Args {}
sub file_GET {
    my ( $self, $c, @args ) = @_;
    $c->forward($c->controller('Report')->action_for('file'), \@args);
}

sub load_node : Chained('base') PathPart('load_node') ActionClass('REST') Args(0) { }
sub load_node_GET {
    my ( $self, $c ) = @_;

    my $job_id         = $c->req->param('job_id');
    my $full_node_path = $c->req->param('node_id');
    my $branch_id      = $c->req->param('branch_id');

    my $job         = $c->model('DB::Job')->find($job_id);
    my $parent_node = $job->get_node($full_node_path);
    my $nodes_rs    = $job->step_results->search({ node => $full_node_path })->default_order;
    my @nodes;
    my $counter = 1;
    while( my $node = $nodes_rs->next ) {
        my $node_id         = join('.', $node->node, $node->node_position);
        my $node_title_text = join(' - ', $counter++, $node->type, $node->name);

        my $bookmark_link = '<a title="Bookmark" href="'
                          . $c->uri_for(
                              $c->controller('Job')->action_for('show'),
                              [ $job->id ],
                              { search => 'position:' . $node->position }
                            )
                          . '" class="pull-right"><i class="glyphicon glyphicon-bookmark"></i></a>';

        my $show_link = '';
        my $edit_link = '';
        if ( defined $node->test_id && defined $node->step_id ) {
            $edit_link = '<a title="Edit step" href="'
                       . $c->uri_for(
                           $c->controller('Step')->action_for('edit'),
                           [ $branch_id, $node->test_id, $node->step_id ]
                       )
                       . '" class="pull-right"><i class="glyphicon glyphicon-pencil"></i></a>';
            $show_link = '<a title="Show step definition" href="'
                       . $c->uri_for(
                           $c->controller('Test')->action_for('show'),
                           [ $branch_id, $node->test_id ]
                       )
                       . '#step-' . $node->step_id . '" '
                       . 'class="pull-right"><i class="glyphicon glyphicon-eye-open"></i></a>';

        }

        my %class_lookup = (
            error   => 'node-danger',
            success => 'node-success',
        );
        my $class = exists $class_lookup{ $node->status }
                    ? $class_lookup{ $node->status }
                    : 'node-default';

        push(
            @nodes,
            {
                title   => $node_title_text . $bookmark_link . $show_link . $edit_link,
                body    => '<pre>' . encode_entities($node->details) . '</pre>',
                classes => [$class],
                (any { $node->type eq $_ } @{ $c->model('DB')->schema->subtest_types() })
                ? ( url => '' . $c->uri_for(
                                    $c->controller('API::Job')->action_for('load_node'),
                                    { job_id => $job->id, node_id => $node_id, branch_id => $branch_id }
                                )
                  )
                : (),
            },
        );
    }
    if (!@nodes) {
        push( @nodes, { title => 'No steps available.' } );
    }

    $self->status_ok(
        $c,
        entity => {
            name => $parent_node->name,
            child_nodes => \@nodes,
        },
    );
}
__PACKAGE__->meta->make_immutable;
1;
