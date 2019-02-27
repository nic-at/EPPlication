#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use
  DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator::ScriptHelpers
  'schema_from_schema_loader';

schema_from_schema_loader(
    { naming => { ALL => 'v8', force_ascii => 1 } },
    sub {
        my ( $schema, $versions ) = @_;

        my $role_name = 'can_create_branches';
        say "Add role: $role_name";
        my $role_rs = $schema->resultset('Role');
        my $role = $role_rs->create( { name => $role_name } );
    }
);
