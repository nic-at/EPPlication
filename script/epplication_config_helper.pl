#!/usr/bin/env perl
use strict;
use warnings;
use Template;
use FindBin qw/$Bin/;
use Getopt::Long;

my $user;
my $group;
my $perl;
my $max_procs;
my $db_user;
my $db_password;
my $db_name;
my $db_host;
my $db_port;
my $job_export_dir;
my $ssh_private_key_path;
my $ssh_public_key_path;
GetOptions(
    "user=s"                 => \$user,
    "group=s"                => \$group,
    "perl=s"                 => \$perl,
    "max-procs=i"            => \$max_procs,
    "db-user=s"              => \$db_user,
    "db-password=s"          => \$db_password,
    "db-name=s"              => \$db_name,
    "db-host=s"              => \$db_host,
    "db-port=s"              => \$db_port,
    "job-export-dir=s"       => \$job_export_dir,
    "ssh-private-key-path=s" => \$ssh_private_key_path,
    "ssh-public-key-path=s"  => \$ssh_public_key_path,
) or die("Error in command line arguments\n");

my %vars = (
    user                 => $user,
    group                => $group,
    perl                 => $perl,
    max_procs            => $max_procs,
    db_user              => $db_user,
    db_password          => $db_password,
    db_name              => $db_name,
    db_host              => $db_host,
    db_port              => $db_port,
    job_export_dir       => $job_export_dir,
    ssh_private_key_path => $ssh_private_key_path,
    ssh_public_key_path  => $ssh_public_key_path,
);

# config for templates
my $tt_config = {
    OUTPUT_PATH => "$Bin/..",
    DEBUG       => 1
};

my $config_template = <<'HERE';
use strict;
use warnings;

my $config = {
    [%- IF ( db_name && db_host && db_port ) || db_user || db_password || job_export_dir %]
    'Model::DB' => {
        [%- IF ( db_name && db_host && db_port ) || db_user || db_password %]
        connect_info => {
            [%- IF db_name && db_host && db_port %]
            dsn      => 'dbi:Pg:dbname=[% db_name %];host=[% db_host %];port=[% db_port %]',
            [%- END %]
            [%- IF db_user %]
            user     => '[% db_user %]',
            [%- END %]
            [%- IF db_password %]
            password => '[% db_password %]',
            [%- END %]
        },
        [%- END %]
        [%- IF job_export_dir %]
        job_export_dir => '[% job_export_dir %]',
        [%- END %]
    },
    [%- END %]
    [%- IF user %]
    user  => '[% user %]',
    [%- END %]
    [%- IF group %]
    group => '[% group %]',
    [%- END %]
    [%- IF perl %]
    perl  => '[% perl %]',
    [%- END %]
    [%- IF max_procs %]
    TaskRunner => {
        max_procs => [% max_procs %],
    }
    [%- END %]
    [%- IF ssh_private_key_path %]
    ssh_private_key_path => '[% ssh_private_key_path %]',
    [%- END %]
    [%- IF ssh_public_key_path %]
    ssh_public_key_path  => '[% ssh_public_key_path %]',
    [%- END %]
};

return $config;
HERE

my $tt = Template->new($tt_config);
$tt->process( \$config_template, \%vars )
  or die $tt->error();
