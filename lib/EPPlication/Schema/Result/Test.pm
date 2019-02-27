package EPPlication::Schema::Result::Test;
use strict;
use warnings;
use List::Util qw/ any /;

use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/ Core /);
__PACKAGE__->table('test');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'int',
        is_numeric        => 1,
        is_auto_increment => 1
    },
    name => { data_type => 'varchar' },
    branch_id  => {
        data_type      => 'int',
        is_numeric     => 1,
        is_foreign_key => 1,
    },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint('test_branch_id_name' => [qw/ branch_id name /]);
__PACKAGE__->resultset_class('EPPlication::Schema::ResultSet::Test');

__PACKAGE__->belongs_to(
    'branch',
    'EPPlication::Schema::Result::Branch',
    'branch_id',
);
__PACKAGE__->has_many(
    'steps',
    'EPPlication::Schema::Result::Step',
    'test_id',
);

__PACKAGE__->has_many(
    'test_tags',
    'EPPlication::Schema::Result::TestTag',
    'test_id',
);

__PACKAGE__->many_to_many(
    'tags',
    'test_tags',
    'tag',
);

__PACKAGE__->has_many(
    'jobs',
    'EPPlication::Schema::Result::Job',
    'test_id',
    { cascade_copy => 0, cascade_delete => 0 },
);

sub clone {
    my ($self, $changes) = @_;
    $changes //= {};
    my $clone = $self->copy($changes);
    return $clone;
}

sub subtest_steps {
    my ($self) = @_;

    my $subtest_types = $self->result_source->schema->subtest_types;
    return $self->steps->search( {type => $subtest_types });
}

sub subtests {
    my ($self) = @_;

    # get subtests
    my $subtest_steps = $self->subtest_steps->search(undef, {select => [qw/ parameters /]});
    my %subtest_ids;
    while ( my $subtest_step = $subtest_steps->next ) {
        $subtest_ids{ $subtest_step->parameters->{subtest_id} } = 1;
    }

    my $subtests = $self->result_source->schema->resultset('Test')->search({
            id => { -in => [ keys %subtest_ids ] }
        });
    return $subtests;
}
sub causes_circular_ref {
    my ($self, $subtest_id) = @_;
    my $schema = $self->result_source->schema;
    $schema->txn_begin;
    $self->steps->create(
        {
            name       => '__temp_subtest_for' . $self->name . '__',
            type       => 'SubTest',
            parameters => { subtest_id => $subtest_id },
        }
    );
    my $ret = $self->has_circular_ref;
    $schema->txn_rollback;
    return $ret;
}
sub has_circular_ref {
    my ($self, %visited_tests) = @_;
    %visited_tests = %visited_tests ? %visited_tests : ();

    return 1
        if exists $visited_tests{ $self->id };

    $visited_tests{ $self->id } = 1;

    my $subtests = $self->subtests;
    while ( my $subtest = $subtests->next ) {
        return 1
          if $subtest->has_circular_ref(%visited_tests);
    }

    return 0;
}

# returns a resultset with all tests that directly call $self as SubTest
sub parent_tests {
    my ($self) = @_;

    my $subtest_types = $self->result_source->schema->subtest_types;
    my $steps = $self->result_source->schema->resultset('Step')->search(
            { 'test.branch_id' => $self->branch_id , type => $subtest_types },
            { join => 'test' }
        );

    my %parent_ids;
    while ( my $step = $steps->next ) {
        if ( $step->parameters->{subtest_id} == $self->id ) {
            my $parent_id = $step->test_id;
            $parent_ids{ $parent_id } = 1
        }
    }

    my $parent_tests
        = $self->result_source->schema->resultset('Test')->search({
            id => { -in => [ keys %parent_ids ] }
        });
    return $parent_tests;
}

# build a hash with variable names as keys and
# an ArrayRef of assigned values as value.
sub list_variables {
    my ($self, $vars_hash) = @_;

    $vars_hash //= {};

    # list of types that assign a value to a variable
    my $steps = $self->steps->active->default_order->search(
        {   type => [
                qw/
                    EPPConnect
                    EPP
                    SOAP
                    REST
                    Whois
                    SubTest
                    ForLoop
                    VarVal
                    VarRand
                    VarQueryPath
                    CountQueryPath
                    DateAdd
                    DateFormat
                    Transformation
                    Math
                    SSH
                    DB
                    /
            ]
        }
    );
    while ( my $step = $steps->next ) {
        my $variable_parameter;
        my $value_parameter;

        my $subtest_types = $self->result_source->schema->subtest_types;
        my $type = $step->type;
        if ( any { $type eq $_ } @{ $subtest_types } ) {
            if ( $type eq 'ForLoop' ) {
                _add_value_to_var($vars_hash, $step, 'variable', $step->parameters->{values});
            }
            # recursively build list of variable/value information
            $vars_hash = $step->subtest->list_variables($vars_hash);
        }
        elsif ( any { $type eq $_ } qw/ EPPConnect EPP SOAP REST Whois DB / )
        {
            _add_value_to_var($vars_hash, $step, 'var_result', "response from $type");
        }
        elsif ( $type eq 'VarVal' ) {
            _add_value_to_var($vars_hash, $step, 'variable', $step->parameters->{value});
        }
        elsif ( $type eq 'SSH' ) {
            _add_value_to_var($vars_hash, $step, 'var_stdout', $step->parameters->{command});
        }
        elsif ( $type eq 'VarRand' ) {
            _add_value_to_var($vars_hash, $step, 'variable', $step->parameters->{rand});
        }
        elsif ( any { $type eq $_ } qw/ VarQueryPath CountQueryPath / )
        {
            _add_value_to_var($vars_hash, $step, 'var_result', $step->parameters->{query_path} . ' (' . $step->parameters->{input} . ')');
        }
        elsif ( $type eq 'DateAdd' ) {
            _add_value_to_var($vars_hash, $step, 'variable', $step->parameters->{date} . ' + ' . $step->parameters->{duration});
        }
        elsif ( $type eq 'DateFormat' ) {
            _add_value_to_var($vars_hash, $step, 'variable', $step->parameters->{date_format_str} . ' (' . $step->parameters->{date} . ')');
        }
        elsif ( $type eq 'Transformation' ) {
            _add_value_to_var($vars_hash, $step, 'var_result', $step->parameters->{transformation} . ': ' . $step->parameters->{input});
        }
        elsif ( $type eq 'Math' ) {
            _add_value_to_var($vars_hash, $step, 'variable', $step->parameters->{value_a} . ' ' . $step->parameters->{operator} . ' ' . $step->parameters->{value_b});
        }
        else {
            warn "Unexpected type: " . $step->type;
        }
    }

    return $vars_hash;
}
sub _add_value_to_var {
    my ( $vars_hash, $step, $var, $val ) = @_;

    $vars_hash->{ $step->parameters->{$var} } //= [];
    push(
        @{ $vars_hash->{ $step->parameters->{$var} } },
        $val
    );
}

# return formatted string of list of variables
sub list_variables_as_str {
    my ($self) = @_;
    my $vars_hash = $self->list_variables();

    my $str = q{};
    for my $variable ( sort keys %$vars_hash ) {
        my $values = $vars_hash->{ $variable };
        $str .= sprintf('%-25s', $variable) . ' => ' . shift(@$values) . "\n";
        $str .= ' 'x25 . " => $_\n" for @$values;
    }

    return $str;
}

1;
