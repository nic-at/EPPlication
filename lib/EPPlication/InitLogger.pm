package EPPlication::InitLogger;
use strict;
use warnings;
use EPPlication::Util::Config;
use Log::Any::Adapter;
use Log::Dispatch;
use Log::Dispatch::FileRotate;
use IO::Interactive qw/ is_interactive /;
use POSIX qw/strftime/;

sub init_logger {
    my $config  = EPPlication::Util::Config::get();
    my $log_file = $config->{log_file};

    my @outputs;

    if ( defined $log_file && $log_file ) {
        push(
            @outputs,
            [   'FileRotate',
                name      => 'file',
                filename  => $log_file,
                min_level => 'debug',
                newline   => 1,
                mode      => 'append',
                size      => 10*1024*1024, # 10MB
                max       => 3,            # number of log files to create
                                           # 3 => log.1, log.2, log.3
            ]
        );
    }

    if ( is_interactive() ) {
        push(
            @outputs,
            [
                'Screen',
                name      => 'screen',
                min_level => 'debug',
                newline   => 1,
            ]
        );
    }

    die "No log outputs defined."
        unless scalar @outputs;

    my $logger = Log::Dispatch->new(
        outputs   => \@outputs,
        callbacks => [
            sub {
                my %msg = @_;
                return sprintf(
                    "%s %d %s",
                    strftime("%F %H:%M:%S", localtime),
                    $$,
                    $msg{message}
                );
            }
        ]
    );

    Log::Any::Adapter->set( 'Dispatch', dispatcher => $logger );

}

init_logger();

1;
