#!/usr/bin/env perl

use strict;
use warnings;
use feature qw/ say /;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use EPPlication::Util;
use Getopt::Long;
use Term::ReadKey;
use Pg::CLI::psql;
use Pg::CLI::pg_dump;

my $cmd;
my $from_version;
my $to_version;
my $version;
my $username;
my $password;
my $add_all_roles;
my $create_default_tags;
my $create_default_roles;
my $create_default_branch;
my $file;
my $src_branch;
my $dest_branch;
GetOptions(
    'command|cmd=s'         => \$cmd,
    'from-version|from=i'   => \$from_version,
    'to-version|to=i'       => \$to_version,
    'version=i'             => \$version,
    'username=s'            => \$username,
    'password=s'            => \$password,
    'add-all-roles'         => \$add_all_roles,
    'create-default-roles'  => \$create_default_roles,
    'create-default-tags'   => \$create_default_tags,
    'create-default-branch' => \$create_default_branch,
    'file=s'                => \$file,
    'src-branch=s'          => \$src_branch,
    'dest-branch=s'         => \$dest_branch,
);

sub usage {
    say <<'HERE';
usage:
  database.pl --cmd prepare [ --from-version $from --to-version $to ]
  database.pl --cmd install [ --version $version ]
  database.pl --cmd upgrade
  database.pl --cmd version
  database.pl --cmd database-version
  database.pl --cmd schema-version
  database.pl --cmd init [ --create-default-roles --create-default-tags --create-default-branch ]
  database.pl --cmd adduser [ --username $username --password $password --add-all-roles ]
  database.pl --cmd dump-tests --file $file
  database.pl --cmd delete-tests
  database.pl --cmd restore-tests --file $file
  database.pl --cmd branch --src-branch $src_branch --dest-branch $dest_branch
HERE
    exit(0);
}

if    ( !defined $cmd )              { usage() }
elsif ( $cmd eq 'prepare' )          { prepare() }
elsif ( $cmd eq 'install' )          { install() }
elsif ( $cmd eq 'upgrade' )          { upgrade() }
elsif ( $cmd eq 'version' )          { version() }
elsif ( $cmd eq 'database-version' ) { database_version() }
elsif ( $cmd eq 'schema-version' )   { schema_version() }
elsif ( $cmd eq 'init' )             { init() }
elsif ( $cmd eq 'adduser' )          { adduser() }
elsif ( $cmd eq 'dump-tests' )       { dump_tests() }
elsif ( $cmd eq 'delete-tests' )     { delete_tests() }
elsif ( $cmd eq 'restore-tests' )    { restore_tests() }
elsif ( $cmd eq 'branch' )           { branch() }
else                                 { usage() }

sub prepare {
    say "running prepare_install()";

    usage() unless ($from_version && $to_version);

    my $dh = EPPlication::Util::get_deployment_handler();
    $dh->prepare_install;

    if ( defined $from_version && defined $to_version ) {
        say
            "running prepare_upgrade({ from_version => $from_version, to_version => $to_version })";
        $dh->prepare_upgrade(
            {   from_version => $from_version,
                to_version   => $to_version,
            }
        );
    }
}

sub install {
    my $dh = EPPlication::Util::get_deployment_handler();
    if ( defined $version ) {
        $dh->install( { version => $version } );
    }
    else {
        $dh->install;
    }
}

sub upgrade {
    my $dh = EPPlication::Util::get_deployment_handler();
    $dh->upgrade;
}

sub version {
    my $dh = EPPlication::Util::get_deployment_handler();
    say "schema version:   " . $dh->schema_version;
    say "database version: " . $dh->database_version;
}

sub database_version {
    my $dh = EPPlication::Util::get_deployment_handler();
    say $dh->database_version;
}

sub schema_version {
    my $dh = EPPlication::Util::get_deployment_handler();
    say $dh->schema_version;
}

sub init {
    my $dh = EPPlication::Util::get_deployment_handler();

    $dh->txn_do(
        sub {
            if ($create_default_tags) {
                EPPlication::Util::create_default_tags();
                say "Created default tags.";
            }
            if ($create_default_roles) {
                EPPlication::Util::create_default_roles();
                say "Created default roles.";
            }
            if ($create_default_branch) {
                EPPlication::Util::create_default_branch();
                say "Created default branch.";
            }
        }
    );
}

sub _validate_username {
    my ($username) = @_;
    die "Error: invalid username.\n"
      unless $username =~ m/[a-zA-Z][a-zA-Z0-9]*/xms;
}

sub _validate_password {
    my ($password) = @_;
    die "Error: password too short. minimum 8 characters.\n"
      unless length($password) >= 8;
}

sub _get_user_data {

    # get username
    if ( defined $username ) {
        _validate_username($username);
    }
    else {
        print "Username: ";
        $username = ReadLine(0);
        chomp $username;
        _validate_username($username);
    }

    # get password
    if ( defined $password ) {
        _validate_password($password);
    }
    else {
        print "Password: ";
        ReadMode('noecho');
        $password = ReadLine(0);
        print "\n";
        print 'Repeat password: ';
        my $password_repeat = ReadLine(0);
        ReadMode('restore');
        print "\n";
        die "Error: Passwords do not match.\n"
          unless $password eq $password_repeat;
        chomp $password;
        _validate_password($password);
    }

    return ($username, $password);
}

sub adduser {
    my ($username, $password) = _get_user_data;

    my $dh = EPPlication::Util::get_deployment_handler();

    $dh->txn_do(
        sub {
            my $user = EPPlication::Util::create_user($username, $password);
            say "User '$username' created.";
            if ($add_all_roles) {
                EPPlication::Util::add_all_roles($user);
                say "Added all roles to user '$username'.";
            }
        }
    );
}

sub _get_pg_cli_params {
    my $config   = EPPlication::Util::get_config();
    my $user     = $config->{'Model::DB'}{connect_info}{user};
    my $password = $config->{'Model::DB'}{connect_info}{password};
    my $dsn      = $config->{'Model::DB'}{connect_info}{dsn};

    my %parts  = map { split('=', $_) } split(';', $dsn);

    die "Couldn't parse DSN ($dsn)"
      unless ( exists $parts{'dbi:Pg:dbname'} && exists $parts{host} );

    my $port = exists $parts{port} ? $parts{port} : 5432;

    return ($user, $password, $parts{host}, $parts{'dbi:Pg:dbname'}, $port);
}

sub dump_tests {

    die "Error: dump file exists."
      if (-e $file);

    my ($user, $password, $host, $database, $port) = _get_pg_cli_params;

    my $pg_dump = Pg::CLI::pg_dump->new(
        username => $user,
        password => $password,
        host     => $host,
        port     => $port,
    );

    open( my $fh, '>>', $file )
      or die "Could not open file for writing. ($!)";

    for my $rel (qw/ tag branch test test_tag step/) {
        print "Dumping $rel ... ";
        my $stderr;
        $pg_dump->run(
            database => $database,
            options  => [
                '--format=plain',
                '--data-only',
                "--table=$rel",
                '--column-inserts',
            ],
            stdout   => $fh,
            stderr   => \$stderr,
        );

        die "Error: $stderr" if ($stderr);
        say 'OK';
    }
    say "tests dumped successfully.";
}

sub delete_tests {
    my ($user, $password, $host, $database, $port) = _get_pg_cli_params;

    my $psql = Pg::CLI::psql->new(
        username => $user,
        password => $password,
        host     => $host,
        port     => $port,
    );

    my $stderr;
    my $sql =
        'BEGIN;'
      . 'DELETE FROM "step";'
      . 'DELETE FROM "tag";'
      . 'DELETE FROM "test";'
      . 'DELETE FROM "test_tag";'
      . 'DELETE FROM "branch";'
      . 'COMMIT;';
    say "Deleting tests ...";
    $psql->run(
        database => $database,
        stdin    => \$sql,
        stderr   => \$stderr,
    );
    die "Error: $stderr" if $stderr;
    say "tests deleted successfully.";
}

sub branch {
    die 'You need to provide --src-branch'
        unless $src_branch;
    die 'You need to provide --dest-branch'
        unless $dest_branch;
    my $schema = EPPlication::Util::get_schema();
    my $branch = $schema->resultset('Branch')->find({ name => $src_branch });
    die "Branch $src_branch does not exist."
        unless $branch;
    say "Creating branch $dest_branch from $src_branch";
    $branch->clone($dest_branch);
}

sub restore_tests {

    die "Error: restore file does not exist."
      unless (-e $file);

    my ($user, $password, $host, $database, $port) = _get_pg_cli_params;

    my $psql = Pg::CLI::psql->new(
        username => $user,
        password => $password,
        host     => $host,
        port     => $port,
    );

    my $stderr;
    say "Restoring tests ... ";
    $psql->execute_file(
        database => $database,
        options  => [
            '--single-transaction',
        ],
        stderr   => \$stderr,
        file     => $file,
    );
    die "Error: $stderr" if $stderr;
    say "tests restored successfully.";
}
