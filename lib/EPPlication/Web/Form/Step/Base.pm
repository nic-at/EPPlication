package EPPlication::Web::Form::Step::Base;
use HTML::FormHandler::Moose;
use namespace::autoclean;
extends 'HTML::FormHandler::Model::DBIC';
with 'EPPlication::Web::Role::Form';

has '+item_class' => ( default => 'Step' );
has '+name'       => ( default => 'step' );

has_field 'submit' => (
    type  => 'Submit',
    order => 99,
);

has 'type' => (
    is       => 'ro',
    required => 1,
    isa      => 'Str',
);

# type is set at form instantiation time and cannot be changed
# the user has selected the type in the first step of the
# step creation process (1. select step type, 2. fill in params)
has_field '_type' => (
    label     => 'Type',
    type      => 'Text',
    disabled  => 1,
    noupdate  => 1,
);
sub default__type {
    my ($self) = @_;
    return $self->type;
}

has_field 'highlight' => (
    type    => 'Boolean',
    default => 0,
);

has_field 'active' => (
    type    => 'Boolean',
    default => 1,
);

has_field 'condition' => (
    type         => 'Text',
    default      => '1',
    required     => 1,
    not_nullable => 1,
    element_attr => { class => 'detect-whitespace' },
);

has_field 'name' => (
    type         => 'Text',
    required     => 1,
    element_attr => { class => 'detect-whitespace' },
);

# every step form subclass has to add the names of its parameter fields
has 'parameter_fields' => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    traits  => ['Array'],
    lazy    => 1,
    builder => '_build_parameter_fields',
);
sub _build_parameter_fields {
    return [];
}

# prepare parameters for storing into database
before 'update_model' => sub {
    my $self       = shift;
    my $parameters = {
        map { $_ => $self->field($_)->value } @{ $self->parameter_fields }
    };
    my $item = $self->item;
    $item->type($self->type);
    $item->parameters($parameters);
};

# fill in form using $step->parameters hashref
has '+use_init_obj_when_no_accessor_in_item' => ( default => 1 );
around 'process' => sub {
    my $orig = shift;
    my $self = shift;

    my %hash = @_;
    my $item = exists $hash{item} ? $hash{item} : undef;
    if ( defined $item ) {
        my $parameters = $item->parameters;
        if (defined $parameters) {
            return $self->$orig( @_, init_object => $item->parameters );
        }
    }

    return $self->$orig( @_ );
};

1;
