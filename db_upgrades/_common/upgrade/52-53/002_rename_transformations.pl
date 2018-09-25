#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use EPPlication::Util::SchemaUpgradeHelper qw/ get_params set_params add_param change_param /;

use
  DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator::ScriptHelpers
  'schema_from_schema_loader';

schema_from_schema_loader(
    { naming => { ALL => 'v8', force_ascii => 1 } },
    sub {
        my ( $schema, $versions ) = @_;

        my $step_rs = $schema->resultset('Step')->search( { type => 'Transformation' } );
        say "Update transformation names.";

        while ( my $step = $step_rs->next ) {
            say "Upgrade for step " . $step->id;
            my $params = get_params($step);
            change_param( $params, 'transformation', 'uppercase', 'Uppercase' );
            change_param( $params, 'transformation', 'header_row', 'HeaderRow' );
            change_param( $params, 'transformation', 'header_row_csv', 'HeaderRowCSV' );
            change_param( $params, 'transformation', 'xml2json', 'Xml2Json' );
            change_param( $params, 'transformation', 'undef2emptystr', 'Undef2EmptyStr' );
            change_param( $params, 'transformation', 'parse_whois', 'ParseWhoisAT' );
            set_params($step, $params);
        }
    }
);
