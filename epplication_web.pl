use strict;
use warnings;
use Dir::Self;
# for deployment specific configuration create
# epplication_web_local.pl and return a config hash
#
# vim epplication_web_local.pl
#   my $config_local = {
#       # ...
#   };
#   return $config_local;

my $config = {
    'Plugin::Session' => {
        expires => 60*60*24*365,
    },
    'Model::DB' => {
        connect_info => {
            dsn            => '',
            user           => '',
            password       => '',
            AutoCommit     => 1,
            RaiseError     => 1,
            quote_names    => 1,
            pg_enable_utf8 => 1,
        },
        schema_class  => 'EPPlication::Schema',
        traits        => 'SchemaProxy',
        subtest_types => [qw/ SubTest ForLoop /],
        job_export_dir => __DIR__ . '/root/job_exports',
    },
    deployment_handler_dir => __DIR__ . '/db_upgrades',
    ssh_private_key_path   => __DIR__ . '/ssh_keys/id_rsa',
    ssh_public_key_path    => __DIR__ . '/ssh_keys/id_rsa.pub',
    log_file               => '/var/log/epplication/main.log',
    step_timeout           => 900, # seconds
    step_result_batch_size => 5000,
    TaskRunner => {
        pid_file             => '/var/run/epplication/taskrunner.pid',
        max_procs            => 5,
        interval             => 3,    # check for jobs every x seconds
        maintenance_interval => 3600, # check for maintenance jobs every x seconds
        abort_interval       => 10,   # check for jobs to abort every x seconds
        temp_job_retention   => 5,    # hours to keep temp jobs
        test_job_retention   => 8*24, # hours to keep test jobs
        job_export_retention => 3*31, # days to keep job export files
    },
    FCGI => {
        socket   => '/var/run/epplication/fcgi.socket',
        pid_file => '/var/run/epplication/fcgi.pid',
    },
    user  => '',
    group => '',
    perl  => '',
};

return $config;
