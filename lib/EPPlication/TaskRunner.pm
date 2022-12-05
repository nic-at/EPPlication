package EPPlication::TaskRunner;

use Moose;
use EPPlication::Util;
use EPPlication::Util::Config;
use EPPlication::InitLogger;
use Log::Any qw/$log/;
use DateTime;
use DateTime::Format::Pg;
use Child;
use File::Find;
use Try::Tiny;
use namespace::autoclean;

my $config               = EPPlication::Util::Config->get;
my $schema               = EPPlication::Util::get_schema();
my $interval             = $config->{TaskRunner}{interval};
my $maintenance_interval = $config->{TaskRunner}{maintenance_interval};
my $abort_interval       = $config->{TaskRunner}{abort_interval};
my $max_procs            = $config->{TaskRunner}{max_procs};
my $temp_job_retention   = $config->{TaskRunner}{temp_job_retention};
my $test_job_retention   = $config->{TaskRunner}{test_job_retention};
my $job_export_retention = $config->{TaskRunner}{job_export_retention};
my $job_export_dir       = $config->{'Model::DB'}{job_export_dir};
my @procs                = ();
my $maintenance_time     = time;
my $abort_time           = 0;

# signal handler to forward signal to child processes
$SIG{TERM} = \&shutdown;
$SIG{INT}  = \&shutdown;
sub shutdown {
    my ($signal) = @_;
    $log->info("Shutting down TaskRunner and all running tasks.");
    for my $proc ( @procs ) { abort_job($signal, $proc); }
    exit;
}

sub abort_job {
    my ($signal, $proc) = @_;
    my $job_id = $proc->{job_id};
    my $job = $schema->resultset('Job')->find($job_id);
    $job->update({ status => 'aborted' });
    $log->info( "Abort Job. Sending signal ($signal) to child. (PID: " . $proc->{proc}->pid . ", job_id: $job_id)" );
    $proc->{proc}->kill($signal);
}

sub start_proc {
    my ($sub) = @_;
    my $child = Child->new($sub);
    my $proc = $child->start;
    return $proc;
}

sub process_task {
    my $task   = shift;
    my $job    = $task->{job};
    my $job_id = $job->id;
    my $action = $task->{action};
    if ( $action eq 'abort' ) {
        my ($proc) = grep { $_->{job_id} == $job_id } @procs;
        if ($proc) {
            my $signal = 'TERM';
            abort_job($signal, $proc);
        }
        else {
            $job->update({ status  => 'abort_error' });
            $log->info( "Failed to abort Job. Process not found. (job_id: $job_id )" );
        }
    }
    elsif ( $action eq 'run' ) {
        $job->update({ status => 'in_progress' });
        my $sub = sub {
            local $SIG{INT} = sub {
                my ($signal) = @_;
                $job->update({ status => 'aborted' });
                $log->info("Received $signal signal. Aborting Task.");
                exit;
            };

            # fix same seed problem after forking
            srand; # (semi-)randomly choose a seed

            try {
                my $test_env = EPPlication::Util::get_test_env($schema);
                $job->run($test_env);
            }
            catch {
                my $e = shift;
                $log->error( "$e (job_id: $job_id)" );
                my $comment = defined $job->comment ? $job->comment : '';
                $job->update(
                    {
                        status  => 'error',
                        comment => "[ERROR] $e\n\n$comment",
                    }
                );
            };
        };
        my $proc = start_proc($sub);
        push(@procs, { job_id => $job_id, proc => $proc });
    }
    elsif ( $action eq 'export' ) {
        $job->update({ status => 'exporting' });
        my $sub = sub {
            local $SIG{INT} = sub {
                my ($signal) = @_;
                $log->info("Received $signal signal. Aborting Task.");
                exit;
            };

            try {
                $job->export;
            }
            catch {
                my $e = shift;
                $log->error( "$e (job_id: $job_id)" );
                my $comment = defined $job->comment ? $job->comment : '';
                $job->update(
                    {
                        status  => 'export_error',
                        comment => "[ERROR] $e\n\n$comment",
                    }
                );
            };
        };
        start_proc($sub);
    }
    elsif ( $action eq 'delete' ) {
        try {
            $job->update({ status => 'deleting' });
            $log->info( "Deleting job (job_id: $job_id)" );
            $job->delete;
        }
        catch {
            my $e = shift;
            $log->error($e);
        };
    }
    else {
        $log->warn( 'Unknown Task action: ' . $action );
    }
}

sub start {
    $log->info("Starting TaskRunner");
    while (1) {
        if ((time - $abort_time) > $abort_interval) {
            my $task = get_abort_task();
            if ($task) {
                process_task($task);
                next;
            }
        }
        if ( free_procs() ) {
            my $task = get_task();
            if ($task) {
                process_task($task);
                next;
            }

            if ((time - $maintenance_time) > $maintenance_interval) {
                my $task = get_maintenance_task();
                if ($task) {
                    process_task($task);
                    next;
                }
            }
        }
        sleep $interval;
        update_procs();
    }
}

sub maintenance_proc_available {
    if ($max_procs > 1) {
        return free_procs() > 1 ? 1 : 0;
    }
    else {
        return free_procs() ? 1 : 0;
    }
}

sub free_procs {
    return $max_procs - scalar @procs;
}

sub update_procs {
    @procs = grep { ! $_->{proc}->is_complete; } @procs;
}

sub get_abort_task {
    my $job = $schema->resultset('Job')
                     ->search({ status => 'aborting' })
                     ->order_oldest_first->first;
    if ($job) {
        return { action => 'abort', job => $job };
    }
    else {
        $abort_time = time;
        return;
    }
}

sub get_maintenance_task {
    # dont use last available proc for maintenance tasks
    return if !maintenance_proc_available();

    {    # finished jobs older then retention time are scheduled for export
        my $date_str =
          DateTime::Format::Pg->format_datetime(
            DateTime->now( time_zone => 'UTC' )
                    ->subtract(hours => $test_job_retention) );
        $schema->resultset('Job')->search(
            {
                status  => 'finished',
                type    => 'test',
                created => { '<' => $date_str },
            }
        )->update({ status => 'export_pending' });
    }

    {    # export jobs (including manually scheduled export jobs)
        my $job = $schema->resultset('Job')
                          ->search({ status  => 'export_pending' })
                          ->order_oldest_first->first;
        return { action => 'export', job => $job } if $job;
    }

    {    # delete temp jobs
        my $date_str =
          DateTime::Format::Pg->format_datetime(
            DateTime->now( time_zone => 'UTC' )
                    ->subtract(hours => $temp_job_retention) );
        my $job = $schema->resultset('Job')->search(
            {
                type    => 'temp',
                created => { '<' => $date_str },
            }
        )->order_oldest_first->first;
        return { action => 'delete', job => $job } if $job;
    }

    {    # delete exported, old, non-sticky test jobs
        my $date_str =
          DateTime::Format::Pg->format_datetime(
            DateTime->now( time_zone => 'UTC' )
                    ->subtract(hours => $test_job_retention) );
        my $job = $schema->resultset('Job')->search(
            {
                status  => 'exported',
                type    => 'test',
                created => { '<' => $date_str },
                sticky  => 0,
            }
        )->order_oldest_first->first;
        return { action => 'delete', job => $job } if $job;
    }

    {    # delete old job exports
        my $retention_date = DateTime->today( time_zone => 'UTC' )
                                     ->subtract(days => $job_export_retention);
        find(
            sub {
                my $file = $File::Find::name;
                # .../2017/7/20/20170720_id168.txt.bz2
                if ($file =~ m/
                                \/
                                (\d{4})
                                \/
                                (\d{1,2})
                                \/
                                (\d{1,2})
                                \/
                                \d{8}_id\d+
                                \.txt\.bz2$
                    /xms) {
                    my $file_date = DateTime->new( year => $1, month => $2, day => $3 );
                    if ($file_date < $retention_date) {
                        $log->info("rm $file ($file_date < $retention_date)");
                        unlink $file;
                    }
                }
            },
            $job_export_dir
        );
    }

    $maintenance_time = time;
    $log->info('Stop maintenance.');
    return;
}

sub get_task {
    # get pending jobs
    my $job = $schema->resultset('Job')
                     ->search({ status => 'pending' })
                     ->order_oldest_first->first;
    return { action => 'run', job => $job } if $job;
}

__PACKAGE__->meta->make_immutable;
1;
