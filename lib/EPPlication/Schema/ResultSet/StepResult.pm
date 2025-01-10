package EPPlication::Schema::ResultSet::StepResult;
use base 'DBIx::Class::ResultSet';
use strict;
use warnings;

sub default_order {
    my ( $self ) = @_;
    my $alias = $self->current_source_alias;
    return $self->search_rs(
        undef,
        {
            order_by => { -asc => [ "$alias.job_id", "$alias.position" ] },
        }
    );
}

# helper sub to put together a case insensitive
# search using literal SQL
sub _lc_search {
    my ( $col, $query ) = @_;
    return -and => [ \[ "LOWER($col) LIKE ?", $query ], ];
}

sub _prepare_query {
    my ($query) = @_;
    $query =~ s/%/\%/g;
    $query =~ s/_/\_/g;
    return lc($query);
}

sub search_name {
    my ( $self, $query ) = @_;

    return $self
        if ( !defined $query ) || ( length($query) == 0 );

    my $alias = $self->current_source_alias;
    return $self->search_rs(
        {
            _lc_search("$alias.name", '%' . _prepare_query($query) . '%')
        },
    );
}
sub search_details {
    my ( $self, $query ) = @_;

    return $self
        if ( !defined $query ) || ( length($query) == 0 );

    my $alias = $self->current_source_alias;
    return $self->search_rs(
        {
            _lc_search("$alias.details", '%' . _prepare_query($query) . '%')
        },
    );
}
sub search_node {
    my ( $self, $query ) = @_;

    return $self
        if ( !defined $query ) || ( length($query) == 0 );

    return $self->search_rs(
        {
            'node' => { -like => "$query%" },
        },
    );
}
sub search_type {
    my ( $self, $query ) = @_;

    return $self
        if ( !defined $query ) || ( length($query) == 0 );

    my $alias = $self->current_source_alias;
    return $self->search_rs(
        {
            _lc_search("$alias.type", _prepare_query($query))
        },
    );
}
sub search_status {
    my ( $self, $query ) = @_;

    return $self
        if ( !defined $query ) || ( length($query) == 0 );

    return $self->search_rs(
        {
            'status' => $query,
        },
    );
}

1;
