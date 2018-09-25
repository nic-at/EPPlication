package EPPlication::Step::PrintVars;

use Moose;
use EPPlication::Role::Step::Parameters;
use Clone qw(clone);

with
    'EPPlication::Role::Step::Base',
    'EPPlication::Role::Step::Util::Encode',
    Parameters( parameter_list => [qw/ filter /] );

sub process {
    my ($self) = @_;

    my $stash = $self->_filter_stash();

    $self->add_detail( 'Variables:', $self->pl2str($stash), );

    return $self->result;
}

sub _filter_stash {
    my ($self)     = @_;
    my $filter_raw = $self->filter;
    my $filter     = $self->process_template($filter_raw);

    my $stash;

    if ($filter) {
        $self->add_detail( "\nFilter: " . $filter );
        $stash = clone( $self->stash );
        my $global_stash  = $stash->{global};
        my $default_stash = $stash->{default};

        for my $s ( $stash->{global}, $stash->{default} ) {
            while ( my ( $key, $value ) = each %$s) {
                delete $s->{$key}
                    if ( index( $key, $filter ) == -1 );
            }
        }
    }
    else {
        $stash = $self->stash;
    }

    return $stash;
}

__PACKAGE__->meta->make_immutable;
1;
