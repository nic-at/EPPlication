#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

# schema upgrade v26-v27
# try to add user to existing jobs according to tags

use
  DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator::ScriptHelpers
  'schema_from_schema_loader';

schema_from_schema_loader(
    { naming => { ALL => 'v8', force_ascii => 1 } },
    sub {
        my ( $schema, $versions ) = @_;
        # removed code because it contained sensitive data
        # this should have been a fixup script rather then a DB migration
    }
);
