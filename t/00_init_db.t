#!/usr/bin/env perl
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use EPPlication::TestKit;

######################################
### prepare empty testing database ###
######################################
# su - postgres
# psql
# DROP DATABASE epplication_testing;
# CREATE DATABASE epplication_testing WITH TEMPLATE template1 OWNER epplication;
# EPPLICATION_DO_INIT_DB=1 prove -lvr t

SKIP: {
    skip('Set EPPLICATION_DO_INIT_DB=1 if you want database initialization.', 2)
        unless $ENV{ EPPLICATION_DO_INIT_DB };

    # db deployment warns to inform user about
    # implicitely created sequences or indices
    my @warnings = warnings {
        is(
            exception {
                my $dh = EPPlication::Util::get_deployment_handler();
                $dh->install;
            },
            undef,
            'Database installed without exceptions.'
        );
    };
    for my $warning (@warnings) {
        if ( $warning !~ m/NOTICE.*create\ implicit/xms ) {
            warn $warning;
        }
    }


    EPPlication::Util::create_default_tags();
    diag "Created default tags.";
    EPPlication::Util::create_default_roles();
    diag "Created default roles.";
    EPPlication::Util::create_default_branch();
    diag "Created default branch.";
    my $user   = EPPlication::Util::create_user('testuser', 'testpassword');
    my $schema = EPPlication::Util::get_schema();
    my @roles  = $schema->resultset('Role')->all;
    for my $role (@roles) {
        $user->add_to_roles($role);
    }
    diag "Created user 'testuser'.";
    ok($user, "User 'testuser' created.");
};

done_testing();
