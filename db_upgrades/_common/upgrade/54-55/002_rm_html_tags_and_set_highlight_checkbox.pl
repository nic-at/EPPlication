#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use EPPlication::Util::SchemaUpgradeHelper qw/ /;

use
  DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator::ScriptHelpers
  'schema_from_schema_loader';

schema_from_schema_loader(
    { naming => { ALL => 'v8', force_ascii => 1 } },
    sub {
        my ( $schema, $versions ) = @_;

        my $step_rs = $schema->resultset('Step')
          ->search( { type => 'Comment', name => { -like => ['%<%>%', '#%', '==%', '--%'] } } );
        say "rm html tags (b, h4, h5) and set highlight => 1.\nalso highlight steps beginning with '#', '==' or '--'.";

        while ( my $step = $step_rs->next ) {
            say "Upgrade for step " . $step->id;
            my $name = $step->name;
            $name =~ s!</?(?:b|h4|h5)\b.*?>!!g;
            $step->update(
                {
                    name      => $name,
                    highlight => 1,
                }
            );
        }
    }
);
