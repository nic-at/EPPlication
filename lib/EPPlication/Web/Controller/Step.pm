package EPPlication::Web::Controller::Step;
use Moose;
use List::Util qw/ any none /;

BEGIN {
    extends 'CatalystX::Resource::Controller::Resource';
    with 'CatalystX::Resource::TraitFor::Controller::Resource::Form';
    with 'CatalystX::Resource::TraitFor::Controller::Resource::Edit';
    with 'CatalystX::Resource::TraitFor::Controller::Resource::Create';
    with 'CatalystX::Resource::TraitFor::Controller::Resource::Delete';
    with 'CatalystX::Resource::TraitFor::Controller::Resource::Sortable';
}

use Module::Pluggable
    search_path => 'EPPlication::Web::Form::Step',
    except      => 'EPPlication::Web::Form::Step::Base';

__PACKAGE__->config(
    parent_key             => 'test',
    parents_accessor       => 'steps',
    resultset_key          => 'steps',
    resource_key           => 'step',
    form_class             => 'EPPlication::Web::Form::Step::Base',
    model                  => 'DB::Step',
    redirect_mode          => 'show_parent',
    form_template          => 'step/form.tt',
    traits                 => [qw/ -Show -List /],
    actions                => {
        base => {
            Chained  => '/test/base_with_id',
            PathPart => 'step',
        },
    },
);

has 'types' => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    traits  => ['Array'],
    default => sub {
        my $self = shift;
        return [ sort $self->plugins ];
    },
);

# Steps are created in a 2-step process
# /steps/select displays a link for each step type
# if you click a link you get a form for the selected step type
sub select : Chained('/step/base') Args(0) {
    my ( $self, $c ) = @_;
    my $loaded_type_names = remove_class_prefix_from_types( $self->types );

    my @type_groups = (
        [qw/ SubTest ForLoop /],
        [qw/ Comment PrintVars ClearVars /],
        [qw/ Math Transformation /],
        [qw/ DateAdd DateCheck DateFormat /],
        [qw/ VarCheck VarCheckRegExp DataCmp Diff /],
        [qw/ VarVal VarRand Multiline/],
        [qw/ VarQueryPath CountQueryPath /],
        [qw/ EPP EPPConnect EPPDisconnect /],
        [qw/ HTTP REST SOAP Whois /],
        [qw/ DB DBConnect DBDisconnect /],
        [qw/ SSH Script /],
    );

    #
    # find loaded types missing in @type_groups and add them
    # at the end
    #
    my @types_in_type_groups = map { @$_ } @type_groups;
    my @missing;
    for my $type_name (@$loaded_type_names) {
        push(@missing, $type_name)
          if none { $_ eq $type_name } @types_in_type_groups;
    }
    push(@type_groups, \@missing)
      if scalar @missing;

    $c->stash( type_groups => \@type_groups );
}

# expects an array of classnames (e.g.: EPPlication::Web::Form::Step::Comment)
# and returns an array of strings (e.g.: Comment)
sub remove_class_prefix_from_types {
    my ( $types ) = @_;
    return [ map { (split('::',$_))[-1] } @$types ];
}

sub set_form_class {
    my ($self, $type) = @_;
    my $class_prefix = 'EPPlication::Web::Form::Step::';
    die qq{Invalid Step Type: "$type"}
        if none { $class_prefix . $type eq $_ } @{ $self->types() };
    $self->form_class( $class_prefix . $type );
}

sub _prepare_form {
    my ($self, $c, $type) = @_;

    $self->set_form_class($type);

    # this value will be used as $item->type
    # when the step is inserted into the DB
    $c->stash->{form_attrs_new}{type} = $type;

    my $subtest_types = $c->model('DB')->schema->subtest_types;

    # show tag selection only for SubTest steps
    if ( any { $type eq $_ } @$subtest_types )  {
        $c->stash->{render_tag_select} = 1;
        $c->stash->{form_attrs_new}{tests_rs} = $c->model('DB::Test');
    }
}

before 'create' => sub {
    my ($self, $c) = @_;
    my $type = $c->req->param('type');

    # make sure default values on fields that have a db-item accessor are used
    # instead of the db-row value which is undef for an empty row
    # (even if it has a DBIC default_value, e.g. $step->condition)
    $c->stash->{form_attrs_process}{use_defaults_over_obj} = 1;

    $self->_prepare_form($c, $type);
};
before 'edit' => sub {
    my ($self, $c) = @_;
    my $type = $c->stash->{step}->type;
    $self->_prepare_form($c, $type);
    $c->stash->{activate_form_fields} = ['hidden_subtest_id'];
};

__PACKAGE__->meta->make_immutable;
1;
