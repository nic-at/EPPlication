package EPPlication::Schema::Result::Job;
use strict;
use warnings;
use feature qw/ say /;
use base 'DBIx::Class';
use IO::Compress::Bzip2 qw/bzip2 $Bzip2Error/;
use Path::Class;
use Try::Tiny;
use Log::Any qw/$log/;
use List::Util qw/ any /;
use POSIX qw/strftime/;

__PACKAGE__->load_components(qw/ InflateColumn::Serializer TimeStamp Core /);
__PACKAGE__->table('job');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        is_auto_increment => 1,
        is_numeric        => 1,
    },
    test_id => {
        data_type      => 'int',
        is_numeric     => 1,
        is_foreign_key => 1,
        is_nullable    => 1,
    },
    user_id => {
        data_type      => 'int',
        is_numeric     => 1,
        is_foreign_key => 1,
        is_nullable    => 1,
    },
    config_id => {
        data_type      => 'int',
        is_numeric     => 1,
        is_foreign_key => 1,
        is_nullable    => 1,
    },
    type => {
        data_type => 'varchar',
    },
    comment => {
        data_type   => 'varchar',
        is_nullable => 1,
    },
    duration => {
        data_type   => 'varchar',
        is_nullable => 1,
    },
    num_steps => {
        data_type   => 'int',
        is_nullable => 1,
    },
    errors => {
        data_type   => 'int',
        is_nullable => 1,
    },
    status => {
        data_type     => 'varchar',
        default_value => 'pending',
    },
    sticky => {
        data_type     => 'boolean',
        default_value => 0,
    },
    created => {
        data_type     => 'datetime',
        set_on_create => 1,
        timezone      => 'UTC',
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
    'test',
    'EPPlication::Schema::Result::Test',
    'test_id',
    { join_type => 'left', on_delete => 'SET NULL' },
);

__PACKAGE__->belongs_to(
    'user',
    'EPPlication::Schema::Result::User',
    'user_id',
    { join_type => 'left', on_delete => 'SET NULL' },
);

__PACKAGE__->belongs_to(
    'config',
    'EPPlication::Schema::Result::Test',
    'config_id',
    { join_type => 'left', on_delete => 'SET NULL' },
);

__PACKAGE__->has_many(
    'step_results',
    'EPPlication::Schema::Result::StepResult',
    'job_id',
    { cascade_copy => 0 },
);

sub get_summary {
    my ($self) = @_;

    return {
        errors    => $self->errors,
        num_steps => $self->num_steps,
        duration  => $self->duration,
    };
}

# writes job results to file and returns
# the filesystem path relative to the job_export_dir
sub export {
    my ($self) = @_;

    $log->info( "Exporting Job (id: " . $self->id . ")" );

    my $file_txt = $self->_get_job_export_file;
    my $file_bz2 = file("$file_txt.bz2");

    die "Uncompressed export file exists: $file_txt"
        if -e $file_txt->stringify;
    die "Job already exported: $file_bz2"
        if -e $file_bz2->stringify;

    my @components     = $file_bz2->components;
    my @rel_components = @components[ -4 .. -1 ];
    my $location       = file(@rel_components);

    $log->info( "Export file for job " . $self->id . ": $file_bz2" );
    _write_export_file( $self, $file_txt, $file_bz2 );

    $self->update( { status  => 'exported' } );
    $log->info( "Finished exporting job (id: " . $self->id . ")" );
    return $location;
}

sub _write_export_file {
    my ( $self, $file_txt, $file_bz2 ) = @_;

    my $fh = $file_txt->open('>:utf8')
      or die "cannot open > $file_txt->stringify ($!)";

    say $fh 'Job';
    say $fh "\tid: " . $self->id;
    if (defined $self->config) {
        say $fh "\tConfig id:   " . $self->config_id;
        say $fh "\tConfig name: " . $self->config->name;
    }
    if (defined $self->test) {
        say $fh "\tBranch:    " . $self->test->branch->name;
        say $fh "\tTest id:   " . $self->test_id;
        say $fh "\tTest name: " . $self->test->name;
    }
    if (defined $self->user) {
        say $fh "\tUser id:   " . $self->user_id;
        say $fh "\tUser name: " . $self->user->name;
    }
    say $fh "\ttype:      " . $self->type;
    say $fh "\tcomment:   " . (defined $self->comment ? "\n" . $self->comment : 'undef');
    say $fh "\tcreated:   " . $self->created;
    say $fh "\tduration:  " . $self->duration;
    say $fh "\tnum_steps: " . $self->num_steps;
    say $fh "\terrors:    " . (defined $self->errors ? $self->errors : 'undef');
    say $fh "\tstatus:    " . $self->status;
    say $fh "\n\n";

    my $result_rs = $self->step_results->default_order;
    my $pager     = $result_rs->search( undef, { rows => 1000, page => 1 } )->pager;

    for my $page ( 1 .. $pager->last_page ) {
        my @results = $result_rs->search( undef, { rows => 1000, page => $page } )->all;
        for my $res (@results) {
            say $fh "\n-----";
            say $fh 'node:          ' . (defined $res->node ? $res->node : 'undef');
            say $fh 'node_position: ' . $res->node_position;
            say $fh 'position:      ' . $res->position;
            say $fh 'type:          ' . $res->type;
            say $fh 'test_id:       ' . (defined $res->test_id ? $res->test_id : 'undef');
            say $fh 'step_id:       ' . (defined $res->step_id ? $res->step_id : 'undef');
            say $fh 'status:        ' . $res->status;
            say $fh 'details:';
            say $fh $res->details;
        }
    }

    say $fh "\n\n-----\nJob END";

    close($fh)
      or die "cannot close $file_txt ($!)";

    bzip2( $file_txt->stringify, $file_bz2->stringify, BlockSize100K => 9 )
      or die "bzip2 failed ($Bzip2Error)";

    $file_txt->remove
      or die "removing $file_txt failed ($!)";
}

sub _get_job_export_file {
    my ($self) = @_;

    my $date       = $self->created->set_time_zone('Europe/Vienna');
    my $year       = $date->year;
    my $month      = sprintf('%02d', $date->month);
    my $day        = sprintf('%02d', $date->day);
    my $export_dir = $self->result_source->schema->job_export_dir;
    my $dir        = dir( $export_dir, $year, $month, $day );
    $dir->mkpath;
    $dir->cleanup->resolve;

    my $filename = $year.$month.$day.'_id'.$self->id.'.txt';
    my $file     = $dir->file($filename);
    return $file;
}

sub _prepare_tree_root {
    my ( $self, $results, $steps ) = @_;

    my $job_test = defined $self->test_id ? $self->test : undef;
    die 'Cannot run job because test does not exist. (job_id: ' . $self->id . ')'
        unless defined $job_test;

    my $job_config = defined $self->config_id ? $self->config : undef;

    $log->info( 'Start job. ('
          . 'id: ' . $self->id
          . ', type: ' . $self->type
          . ', user: ' . $self->user->name
          . ', test: ' . $job_test->name
          . ( defined $job_config ? ', config: ' . $job_config->name : '' )
          . ')' );

    push(
        @$results,
        {   # root node
            node          => undef,
            node_position => 1,
            type          => 'SubTest',
            name          => 'root',
            status        => 'ok',
            details       => 'root',
            step_id       => undef,
            test_id       => undef,
        },
    );

    # create but do not insert subtest steps for
    # the config and test to run
    my $position      = 1;
    my $node_position = 1;
    for my $test ($job_config, $job_test) {
        if ( defined $test ) {
            my $subtest = $test->result_source->schema->resultset('Step')->new_result(
                {
                    type          => 'SubTest',
                    name          => $test->name,
                    position      => $position++,
                    parameters    => { subtest_id => $test->id },
                },
            );
            my %subtest_data             = $subtest->get_inflated_columns;
            $subtest_data{node}          = 1;
            $subtest_data{node_position} = $node_position++,
            push( @$steps, \%subtest_data );
        }
    }
}

sub run {
    my ( $self, $env ) = @_;

    my @steps;
    my @results;

    $self->_prepare_tree_root(\@results, \@steps);

    my $result_stats = {};
    my $position     = 1; # absolute position in entire job run
    my $ts_start     = time;
    my $timeout      = delete $env->{step_timeout};
    my $max_results  = delete $env->{step_result_batch_size};
    my $step_factory = delete $env->{step_factory};

    while ( defined (my $step_data = shift(@steps)) ) {

        my $step = $step_factory->create({ %$step_data, %$env });

        try {
            {
                local $SIG{ALRM} = sub { die "Timeout. Aborted step after $timeout seconds.\n" };
                alarm($timeout);
                push( @results, $step->process() );
                alarm(0);
            }

            # for subtests get all subtests steps
            # and unshift them on the array of steps to process next
            if ( any { $step->type eq $_ } @{ $self->result_source->schema->subtest_types } ) {
                my $node          = $step->node . '.' . $step->node_position;
                my @subtest_steps = @{ $step->subtest_steps };
                my $node_position = 1;
                for (@subtest_steps) {
                    $_->{node}          = $node;
                    $_->{node_position} = $node_position++;
                }
                unshift( @steps, @subtest_steps );
            }
        }
        catch {
            my $e = shift;
            $log->info($e);
            $step->add_detail( "\n[ERROR]\n$e" );
            $step->status( 'error' );
            push(@results, $step->result);
        };

        $self->_process_results( \$position, $result_stats, \@results, $ts_start )
          if ( scalar @results >= $max_results || !scalar @steps );
    }

    $self->update( { status  => 'finished' } );
    $log->info( 'Finished job. (id: ' . $self->id . ', ' . $result_stats->{num_steps} . ' steps)' );
    return $result_stats;
}

# write result to DB and calculate statistics
# empty @result after processing to free memory
sub _process_results {
    my ( $self, $position_ref, $result_stats, $results, $ts_start ) = @_;
    for my $result (@$results) {
        $result->{position} = $$position_ref++;
        $result_stats->{errors}++
          if $result->{status} eq 'error';
    }
    $self->step_results_rs->populate( $results );
    $result_stats->{num_steps} += scalar @$results;
    $result_stats->{duration} = strftime("%T", gmtime(time - $ts_start));
    @$results = ();
    $self->update(
        {
            num_steps => $result_stats->{num_steps},
            errors    => $result_stats->{errors},
            duration  => $result_stats->{duration},
        }
    );
}

sub get_node {
    my ( $self, $full_node_path ) = @_;

    my $pos_last_dot = rindex( $full_node_path, '.' );
    if ( $pos_last_dot == -1 ) {
        return $self->step_results->search( { node => undef } )->single;
    }
    else {
        my $node = substr( $full_node_path, 0, $pos_last_dot );
        my $pos  = substr( $full_node_path, $pos_last_dot + 1 );
        return $self->step_results->search( { node => $node, node_position => $pos } )->single;
    }
}

1;
