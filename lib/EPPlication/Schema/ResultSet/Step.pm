package EPPlication::Schema::ResultSet::Step;
use base 'DBIx::Class::ResultSet';
use strict;
use warnings;

sub default_order {
    my ( $self ) = @_;
    my $alias = $self->current_source_alias;
    return $self->search_rs(
        undef,
        { order_by => { -asc => [ "$alias.test_id", "$alias.position" ] } }
    );
}

sub active {
    my ( $self ) = @_;
    my $alias = $self->current_source_alias;
    return $self->search_rs( { active => 1 } );
}

1;
