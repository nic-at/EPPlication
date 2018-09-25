package EPPlication::Role::Step::Base;

use Moose::Role;
requires 'process';
with 'EPPlication::Role::Step::Util::ProcessTemplate';

around 'process' => sub {
    my ($orig, $self) = @_;

    my $condition_raw = $self->condition;

    my $condition;
    if ( $condition_raw eq '0' || $condition_raw eq '1' ) {
        $condition = $condition_raw;
    }
    else {
        $self->add_detail( "condition: '$condition_raw'" );
        $condition = $self->process_template($condition_raw);
        $self->add_detail( "condition: '$condition'" )
          if $condition ne $condition_raw;
    }

    if ( $condition ) {
        return $self->$orig();
    }
    else {
        $self->add_detail( "Step not executed. ('$condition' not true)" );
        return $self->result;
    }
};

has 'type' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'step_id' => (
    is       => 'ro',
    isa      => 'Int',
    init_arg => 'id',
);

has 'test_id' => (
    is  => 'ro',
    isa => 'Int',
);

has 'condition' => (
    is       => 'ro',
    isa      => 'Str',
    default  => '1',
);

has 'node' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has 'node_position' => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has 'name' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

sub stash;
# stub to satisfy "requires 'stash'" without having to
# include this role in a separate 'with' statement
has 'stash' => (
    is       => 'rw',
    isa      => 'HashRef',
    required => 1,
);

sub stash_set {
    my ( $self, $var, $val, $global ) = @_;
    my $type = defined $global && $global ? 'global' : 'default';
    $self->stash->{$type}{$var} = $val;
}

sub stash_get {
    my ( $self, $var ) = @_;
    my $val;
    if ( exists $self->stash->{default}{$var} ) {
        $val = $self->stash->{default}{$var};
    }
    elsif ( exists $self->stash->{global}{$var} ) {
        $val = $self->stash->{global}{$var};
    }
    return $val;
}

sub stash_exists {
    my ( $self, $var ) = @_;
    return 1
        if exists $self->stash->{default}{$var};
    return 1
        if exists $self->stash->{global}{$var};
    return 0;
}

sub stash_defined {
    my ( $self, $var ) = @_;
    return 1
        if defined $self->stash->{default}{$var};
    return 1
        if defined $self->stash->{global}{$var};
    return 0;
}

sub stash_clear {
    my ($self) = @_;
    $self->stash->{default} = {};
}

sub get_stash_for_tt {
    my ($self) = @_;
    return { %{ $self->stash->{global} }, %{ $self->stash->{default} } };
}

sub process_tt_value {
    my ($self, $name, $value_raw, $options) = @_;

    my $before   = exists $options->{before}   ? $options->{before}   : '';
    my $between  = exists $options->{between}  ? $options->{between}  : ': ';
    my $after    = exists $options->{after}    ? $options->{after}    : '';
    my $show_raw = exists $options->{show_raw} ? $options->{show_raw} : 1;

    $self->add_detail($before . $name . $between . $value_raw . $after)
        if $show_raw;
    my $value = $self->process_template($value_raw);
    $self->add_detail( $before . $name . $between . $value . $after )
      if $value ne $value_raw;

    return $value;
}

sub parameters;
# stub to satisfy "requires 'parameters'" without having to
# include this role in a separate 'with' statement
has 'parameters' => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);

has 'status' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'ok',
);

has 'details' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef',
    handles => {
        add_detail => 'push',
    },
    lazy    => 1,
    default => sub {[]},
);

has 'result' => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    builder => '_build_result',
);

sub _build_result {
    my ($self) = @_;

    return {
        details       => join( "\n", @{ $self->details } ),
        name          => $self->name,
        node          => $self->node,
        node_position => $self->node_position,
        type          => $self->type,
        status        => $self->status,
        test_id       => $self->test_id,
        step_id       => $self->step_id,
    };
}

1;
