package EPPlication::Util;
use strict;
use warnings;
use EPPlication::Schema;
use EPPlication::Util::Config;
use DBIx::Class::DeploymentHandler;
use EPPlication::Step::Factory;
use EPPlication::Step::Transformation::Factory;
use EPPlication::Client::DB;
use EPPlication::Client::EPP;
use EPPlication::Client::SOAP;
use EPPlication::Client::REST;
use EPPlication::Client::HTTP;
use EPPlication::Client::Whois;
use EPPlication::Client::Selenium;
use Template;
use Template::Constants qw( :debug );

sub get_config {
    return EPPlication::Util::Config->get;
}

sub get_schema {
    my $config = get_config();
    my $schema = EPPlication::Schema->connect($config->{'Model::DB'}{connect_info});

    $schema->job_export_dir($config->{'Model::DB'}{job_export_dir});
    $schema->subtest_types($config->{'Model::DB'}{subtest_types});
    return $schema;
}

sub get_deployment_handler {
    my $schema = get_schema();
    my $config = get_config();

    my $deployment_handler_dir = $config->{deployment_handler_dir};

    die "'deployment_handler_dir' not configured."
      unless defined $deployment_handler_dir;

    my $dh = DBIx::Class::DeploymentHandler->new(
        {
            schema           => $schema,
            script_directory => $deployment_handler_dir,
            databases        => 'PostgreSQL',
            force_overwrite  => 1,
        }
    );

    die "We only support positive integers for versions."
      unless $dh->schema_version =~ /^\d+$/;

    return $dh;
}

sub get_test_env {
    my $config = get_config();

    for (
        qw/
        ssh_public_key_path
        ssh_private_key_path
        step_timeout
        step_result_batch_size
        /
      )
    {
        die "'$_' not configured." unless defined $config->{$_};
    }

    # $schema might come from EPPlication OR the job process daemon
    my $schema       = shift // get_schema();
    my $tests        = $schema->resultset('Test');
    my $db_client    = EPPlication::Client::DB->new;
    my $epp_client   = EPPlication::Client::EPP->new;
    my $soap_client  = EPPlication::Client::SOAP->new;
    my $rest_client  = EPPlication::Client::REST->new;
    my $http_client  = EPPlication::Client::HTTP->new;
    my $whois_client = EPPlication::Client::Whois->new;
    my $selenium_client = EPPlication::Client::Selenium->new;
    my $step_factory = EPPlication::Step::Factory->new;
    my $transformation_factory = EPPlication::Step::Transformation::Factory->new;
    my $stash        = { global => {}, default => {} };
    my $tt           = Template->new( STRICT => 1 )
      or die $Template::ERROR;

    return {
        db_client              => $db_client,
        epp_client             => $epp_client,
        soap_client            => $soap_client,
        rest_client            => $rest_client,
        http_client            => $http_client,
        whois_client           => $whois_client,
        selenium_client        => $selenium_client,
        tests                  => $tests,
        stash                  => $stash,
        tt                     => $tt,
        step_factory           => $step_factory,
        transformation_factory => $transformation_factory,
        ssh_public_key_path    => $config->{ssh_public_key_path},
        ssh_private_key_path   => $config->{ssh_private_key_path},
        step_timeout           => $config->{step_timeout},
        step_result_batch_size => $config->{step_result_batch_size},
    };
}

sub create_user {
    my ( $username, $password ) = @_;
    my $schema = get_schema();
    my $user   = $schema->resultset('User')->create(
        {
            name     => $username,
            password => $password,
        }
    );
    return $user;
}

sub create_default_roles {
    my ( $username, $password ) = @_;
    my $schema    = get_schema();
    my @rolenames = qw/
      can_see_admin_menu
      can_list_users
      can_create_users
      can_edit_users
      can_delete_users
      can_list_branches
      can_delete_branches
      can_edit_branches
      can_list_tags
      can_create_tags
      can_edit_tags
      can_delete_tags
      /;
    for my $rolename (@rolenames) {
        $schema->resultset('Role')->create( { name => $rolename } );
    }
}

sub add_all_roles {
    my ($user) = @_;
    my $schema = get_schema();
    my @roles  = $schema->resultset('Role')->all;
    for my $role (@roles) {
        $user->add_to_roles($role);
    }
}

sub create_default_tags {
    my $schema = get_schema();
    my @tags   = qw/ config /;
    for my $tag (@tags) {
        $schema->resultset('Tag')->create( { name => $tag, color => '#ffffff' } );
    }
}

sub create_default_branch {
    my $schema = get_schema();
    $schema->resultset('Branch')->create( { name => 'master' } );
}

1;
