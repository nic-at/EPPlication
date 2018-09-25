#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use JSON;

use
  DBIx::Class::DeploymentHandler::DeployMethod::SQL::Translator::ScriptHelpers
  'schema_from_schema_loader';

schema_from_schema_loader(
    { naming => { ALL => 'v8', force_ascii => 1 } },
    sub {
        my ( $schema, $versions ) = @_;

        my $step_rs;

        $step_rs = $schema->resultset('Step')->search({ type => 'CondSubTest' });
        while ( my $step = $step_rs->next ) {
            say 'Merge value_a and value_b into condition ' . $step->id;
            merge_params($step);
        }
    }
);

sub merge_params {
    my ($step) = @_;

    my $params_raw = $step->get_column('parameters');
    my $params = from_json($params_raw);

    my $value_a = delete $params->{value_a};
    my $value_b = delete $params->{value_b};
    say "\t$value_a\t$value_b";

    my ($part1, $type1) = process_value($value_a);
    my ($part2, $type2) = process_value($value_b);

    my $condition;

    if ($type1 eq 'variable' && $type2 eq 'string') {
        $condition = qq/[% $part1 == '$part2' %]/;
    }
    elsif ($type1 eq 'variable' && $type2 eq 'true') {
        $condition = qq/[% $part1 == $part2 %]/;
    }
    elsif ($type2 eq 'variable' && $type1 eq 'string') {
        $condition = qq/[% $part2 == '$part1' %]/;
    }
    elsif ($type2 eq 'variable' && $type1 eq 'true') {
        $condition = qq/[% $part2 == $part1 %]/;
    }
    elsif ($type2 eq 'string' && $type1 eq 'string') {
        $condition = qq/[% '$part2' == '$part1' %]/;
    }
    elsif ($type1 eq 'condition' && $type2 eq 'true') {
        $condition = qq/$part1/;
    }
    elsif ($type2 eq 'condition' && $type1 eq 'true') {
        $condition = qq/$part2/;
    }
    else {
        say "\tcouldnt process values.";
        say "\ta: $part1, $type1";
        say "\tb: $part2, $type2";
        print "\tEnter contition manually: ";
        $condition = <>;
        chomp($condition);
    }

    die "merging values into condition failed"
      unless (
        ( defined $condition )
        && ( $condition =~ m/ ^ \[% .+ %\] $ /xms )
      );

    say "\t$condition";

    $params->{condition} = $condition;

    $step->set_column( 'parameters' => to_json($params) );
    $step->update();
}

sub process_value {
    my ($value) = @_;

    if( $value eq '1') {
        return ($value, 'true');
    }
    elsif (
        $value =~ m/
                    ^
                    \[% \s*
                    ( [a-zA-Z0-9_]+ )
                    \s* %\]
                    $
                /xms
      )
    {
        my $variable = $1;
        return ($variable, 'variable');
    }
    elsif (
        $value =~ m/
                    ^
                    ( [a-zA-Z0-9_.]+ )
                    $
                /xms
      )
    {
        my $string = $1;
        return ($string, 'string');
    }
    elsif (
        $value =~ m/
                    ^
                    \[% \s*
                    [a-zA-Z0-9_]+
                    \s*
                    (?: &&|==|!= )
                    \s*
                    [a-zA-Z0-9_]+
                    \s* %\]
                    $
                /xms
      )
    {
        return ($value, 'condition');
    }
    else {
        return ($value, 'unknown');
    }
}
