package EPPlication::Schema::ResultSet::Job;
use base 'DBIx::Class::ResultSet';
use strict;
use warnings;

sub default_order {
    my ( $self ) = @_;
    my $alias = $self->current_source_alias;
    return $self->search_rs(
        undef,
        { order_by => { -desc => [ "$alias.created" ] } }
    );
    return $self;
}

sub order_oldest_first {
    my ( $self ) = @_;
    my $alias = $self->current_source_alias;
    return $self->search_rs(
        undef,
        { order_by => { -asc => [ "$alias.created" ] } }
    );
    return $self;
}

sub filter_temp {
    my ( $self ) = @_;
    my $alias = $self->current_source_alias;
    return $self->search_rs(
        { "$alias.type" => { '!=' => 'temp' } }
    );
    return $self;
}

1;
