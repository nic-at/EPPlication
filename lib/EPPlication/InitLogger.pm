package EPPlication::InitLogger;
use strict;
use warnings;
use EPPlication::Util::Config;
use Log::Any::Adapter;
use Log::Dispatch;
use IO::Interactive qw/ is_interactive /;
use POSIX qw/strftime/;

# for each process you want to do logging in you have
# to "use EPPlication::InitLogger" once.
# each package that wants to log has to "use Log::Any qw/$log/"

# logrotate sends HUP signal, re-init logger so we write to the correct file.
$SIG{HUP} = sub { init_logger(); };

my $log_entry;

sub init_logger {
    my $config  = EPPlication::Util::Config::get();
    my $log_file = $config->{log_file};

    my @outputs;

    if ( defined $log_file && $log_file ) {
        push(
            @outputs,
            [   'File',
                name      => 'file',
                filename  => $log_file,
                min_level => 'debug',
                newline   => 1,
                mode      => 'append',
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

    Log::Any::Adapter->remove($log_entry) if $log_entry;
    $log_entry = Log::Any::Adapter->set( 'Dispatch', dispatcher => $logger );
}

init_logger();

1;
