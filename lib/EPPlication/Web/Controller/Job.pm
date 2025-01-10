package EPPlication::Web::Controller::Job;
use Moose;
use Parqus;
use namespace::autoclean;

BEGIN {
    extends 'CatalystX::Resource::Controller::Resource';
    with 'CatalystX::Resource::TraitFor::Controller::Resource::List';
    with 'CatalystX::Resource::TraitFor::Controller::Resource::Show';
}

__PACKAGE__->config(
    resultset_key => 'jobs',
    resource_key  => 'job',
    form_class    => 'EPPlication::Web::Form::Job',
    model         => 'DB::Job',
    redirect_mode => 'list',
    traits        => [ qw/ -Create -Show Edit -Delete -List Form /],
    prefetch      => [ qw/ user test config / ],
    actions       => {
        base => {
            Chained  => '/login/required',
            PathPart => 'job',
        },
        show => {
            Chained => 'search',
        }
    },
);

sub export : Chained('base_with_id') PathPart('export') Args(0) {
    my ( $self, $c ) = @_;
    my $job      = $c->stash->{job};
    $job->update({ status => 'export_pending' });
    $c->flash( msg => $job->id . ' scheduled for export.' );
    $c->res->redirect($c->uri_for($self->action_for('list')));
}

sub search : Chained('base_with_id') PathPart('') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    my $job = $c->stash->{job};

    my $query_str = $c->req->query_params->{search};
    if ($query_str) {
        my $parser = Parqus->new( keywords => [qw/ position name  node
                                                   details  limit status
                                                   offset   type  comment
                                              /],
                                );
        my $data = $parser->process($query_str);
        $c->stash( error_msg => join( "\n", @{ $data->{errors} } ) )
          if exists $data->{errors};
        $c->stash( search_query_hash => $data );

        if ( exists $data->{keywords} ) {
            my %query = %{ $data->{keywords} };

            my $search_result = $job->step_results_rs->default_order;
            if ( $query{node} && $query{node}[0] ne '' ) {
                $search_result = $search_result->search_node($query{node}[0]);
            }
            if ( $query{type} && $query{type}[0] ne '' ) {
                $search_result = $search_result->search_type($query{type}[0]);
            }
            if ( $query{status} && $query{status}[0] ne '' ) {
                $search_result = $search_result->search_status($query{status}[0]);
            }
            if ( $query{name} ) {
                $search_result = $search_result->search_name($_) for @{ $query{name} };
            }
            if ( $query{details} ) {
                $search_result = $search_result->search_details($_) for @{ $query{details} };
            }
            if ( $query{position} && $query{position}[0] ne '' ) {
                $search_result = $search_result->search( { position => $query{position}[0] } );
            }
            if ( $query{limit} && $query{limit}[0] ne '' ) {
                $search_result = $search_result->search(undef, { rows => $query{limit}[0] });
            }
            if ( $query{offset} && $query{offset}[0] ne '' ) {
                $search_result = $search_result->search(undef, { offset => $query{offset}[0] });
            }
            $c->stash->{quicklinks} = [ $search_result->all ];
        }
        $c->stash( search_query => $query_str );
    }
    else {
        $c->stash(
            search_query => 'position: name: node: details: type: status:error limit:50 offset:0'
        );
    }
}

sub _create {
    my ( $c, $job_type, $test_id ) = @_;

    my $job = $c->model('DB::Job')->create(
        {
            test_id => $test_id,
            type    => $job_type,
            user_id => $c->user->get('id'),
            exists $c->session->{active_config}
            ? ( config_id => $c->session->{active_config}{id} )
            : (),
        }
    );
    $c->flash->{msg} = "Job has been created. (type: $job_type)";
    return $job,
}
sub create : Chained('/job/base') PathPart('create') Args(2) {
    my ( $self, $c, $job_type, $test_id ) = @_;
    if ($job_type eq 'test') {
        _create($c, $job_type, $test_id);
        $c->res->redirect($c->uri_for($c->controller('Job')->action_for('list')));
    }
    elsif ($job_type eq 'temp') {
        my $job = _create($c, 'temp', $test_id);
        $c->res->redirect($c->uri_for($c->controller('Job')->action_for('show'), [ $job->id ]));
    }
}

__PACKAGE__->meta->make_immutable;
1;
